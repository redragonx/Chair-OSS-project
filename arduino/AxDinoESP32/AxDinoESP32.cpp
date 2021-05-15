//
// Wrapper library for the ProDinoESP32 based wheelchair controller
//
#include "AxDinoESP32.h"
#include <OneWire.h>
#include <DallasTemperature.h>

//
// Private constants
//

// IO Pins
#define AX_IO_SW1 35
#define AX_IO_SW2 27
#define AX_IO_SW3 34
#define AX_IO_SW4 25

#define AX_IO_PI_SNS 15
#define AX_IO_PI_CLR 17
#define AX_IO_PI_EN 26
#define AX_IO_FAN_EN 14

#define AX_IO_OW_TEMP 13


// Evaluation intervals
#define EVAL_MSEC       25
#define TEMP_SENSE_MSEC 5000


//
// Global instantiation of supporting objects
//

OneWire oneWire(AX_IO_OW_TEMP);
DallasTemperature sensors(&oneWire);


//
// Class Definition
//
AxDinoESP32Class AxDinoESP32;

void AxDinoESP32Class::begin()
{
	int i;

	// Initialize IO
	pinMode(AX_IO_SW1, INPUT_PULLUP);
	pinMode(AX_IO_SW2, INPUT_PULLUP);
	pinMode(AX_IO_SW3, INPUT_PULLUP);
	pinMode(AX_IO_SW4, INPUT_PULLUP);
	pinMode(AX_IO_PI_SNS, INPUT_PULLDOWN);

	pinMode(AX_IO_PI_EN, OUTPUT);
	digitalWrite(AX_IO_PI_EN, LOW);
	pinMode(AX_IO_FAN_EN, OUTPUT);
	digitalWrite(AX_IO_FAN_EN, LOW);
	pinMode(AX_IO_PI_CLR, OUTPUT);
	digitalWrite(AX_IO_PI_CLR, LOW);

	// Variables
	auto_fan = true;
	auto_switch = true;
	for (i=0; i<AD_NUM_INS; i++) {
		sw_inputs[i] = false;
		sw_prev_inputs[i] = false;
		sw_down[i] = false;
	}
	for (i=0; i<AD_NUM_OUTS; i++) {
		cur_outputs[i] = false;
		auto_outputs[i] = false;
		man_outputs[i] = false;
	}
	cur_temp_c = 0;
	set_temp_c = AD_FAN_THRESH;

	// Temperature sensor
	sensors.begin();

	// PRODINo ESP32 board
	KMPProDinoESP32.begin(ProDino_ESP32);

	// Access mutex
	access_mutex = xSemaphoreCreateMutex();

	// And finally the monitor/control task
	setStackSize(4000);
	setPriority(2);
	start();
}

float AxDinoESP32Class::getTemp(int units)
{
	float t;

	xSemaphoreTake(access_mutex, portMAX_DELAY);
	t = cur_temp_c;
	xSemaphoreGive(access_mutex);

	if (units == AD_TEMP_F) {
		t = (t * 9.0) / 5.0 + 32.0;
	}

	return t;
}

float AxDinoESP32Class::getFanAutoTemp()
{
	// No need for semaphore protection to read this
	return set_temp_c;
}

void AxDinoESP32Class::setFanAutoTemp(float t, int units)
{
	if (units == AD_TEMP_F) {
		t = (t - 32.0) * 5.0 / 9.0;
	}

	xSemaphoreTake(access_mutex, portMAX_DELAY);
	set_temp_c = t;
	xSemaphoreGive(access_mutex);
}

bool AxDinoESP32Class::getSwitch(int n)
{
	bool ret = false;

	if ((n >= 0) &&  (n < AD_NUM_INS)) {
		xSemaphoreTake(access_mutex, portMAX_DELAY);
		ret = sw_inputs[n];
		xSemaphoreGive(access_mutex);
	}

	return ret;
}

void AxDinoESP32Class::setOutput(int n, bool state)
{
	bool disable_pi_auto_on = false;
	
	if ((n >= 0) && (n < AD_NUM_OUTS)) {
		xSemaphoreTake(access_mutex, portMAX_DELAY);
		man_outputs[n] = state;
		
		if ((n == AD_OUT_PI) && auto_outputs[AD_OUT_PI] && !state) {
			// User has requested to turn Pi off.  If it's on because of the auto-on
			// feature then setup to reset the auto-on flip-flop.
			disable_pi_auto_on = true;
		}
		xSemaphoreGive(access_mutex);
		
		if (disable_pi_auto_on) {
			// Pulse the reset line
			digitalWrite(AX_IO_PI_CLR, HIGH);
			delay(1);
			digitalWrite(AX_IO_PI_CLR, LOW);
		}
	}
}

bool AxDinoESP32Class::getOutput(int n)
{
	bool ret = false;;

	if ((n >= 0) && (n < AD_NUM_OUTS)) {
		xSemaphoreTake(access_mutex, portMAX_DELAY);
		ret = man_outputs[n];
		xSemaphoreGive(access_mutex);
	}

	return ret;
}

bool AxDinoESP32Class::getAutoOutput(int n)
{
	bool ret = false;
	
	xSemaphoreTake(access_mutex, portMAX_DELAY);
	ret = auto_outputs[n];
	xSemaphoreGive(access_mutex);
	
	return ret;
}

bool AxDinoESP32Class::getAutoFan()
{
	// No need for semaphore protection to read this
	return auto_fan;
}

void AxDinoESP32Class::enableAutoFan(bool state)
{
	xSemaphoreTake(access_mutex, portMAX_DELAY);
	auto_fan = state;
	xSemaphoreGive(access_mutex);
}

bool AxDinoESP32Class::getAutoSwitch()
{
	// No need for semaphore protection to read this
	return auto_switch;
}

void AxDinoESP32Class::enableAutoSwitch(bool state)
{
	xSemaphoreTake(access_mutex, portMAX_DELAY);
	auto_switch = state;
	xSemaphoreGive(access_mutex);
}

void AxDinoESP32Class::setLED(RgbColor color)
{
	KMPProDinoESP32.setStatusLed(color);
}


//
// Private routines
//

void AxDinoESP32Class::run(void *data)
{
	bool pi_sns;
	bool sw[AD_NUM_INS];
	bool sw_pressed[AD_NUM_INS];
	bool nxt_outputs[AD_NUM_OUTS];
	bool t_updated;
	int i;
	float t;

	static int t_sample_count = (TEMP_SENSE_MSEC/EVAL_MSEC) - 1;  // Trigger on first evaluation

	while (true) {
		// Get pi auto-on sense input
		pi_sns = digitalRead(AX_IO_PI_SNS) == HIGH ? true : false;
		
		// Get switch inputs and invert
		sw[0] = digitalRead(AX_IO_SW1) == LOW;
		sw[1] = digitalRead(AX_IO_SW2) == LOW;
		sw[2] = digitalRead(AX_IO_SW3) == LOW;
		sw[3] = digitalRead(AX_IO_SW4) == LOW;
		
		// Debounce switch inputs and look for new press detections
		//   Also updates sw_down[i]
		for (i=0; i<AD_NUM_INS; i++) {
			sw_pressed[i] = switchPressed(i, sw[i]);
		}

		// Sample temperature every five seconds since it takes a while
		if (++t_sample_count == (TEMP_SENSE_MSEC/EVAL_MSEC)) {
			t_sample_count = 0;
			sensors.requestTemperatures(); 
			t = sensors.getTempCByIndex(0);
			t_updated = true;
		} else {
			t_updated = false;
		}

		//
		// Atomic state update 
		//
		xSemaphoreTake(access_mutex, portMAX_DELAY);
		
		// Pi auto power on sense
		auto_outputs[AD_OUT_PI] = pi_sns;

		// Switch values
		for (i=0; i<AD_NUM_INS; i++) {
			sw_inputs[i] = sw_down[i];
			if (auto_switch) {
				if (sw_pressed[i]) {
					// Toggle auto output
					auto_outputs[i + AD_OUT_RLY_1] = !auto_outputs[i + AD_OUT_RLY_1];
				}
			} else {
				// Hold auto outputs clear when auto_switch disabled
				auto_outputs[i + AD_OUT_RLY_1] = false;
			}
		}
		
		// Temperature 
		if (t_updated) {
			cur_temp_c = t;
			if (auto_fan) {
				if (auto_outputs[AD_OUT_FAN]) {
					if (cur_temp_c <= (set_temp_c - AD_FAN_HYST)) {
						auto_outputs[AD_OUT_FAN] = false;
					}
				} else {
					if (cur_temp_c > set_temp_c) {
						auto_outputs[AD_OUT_FAN] = true;
					}
				}
			} else {
				auto_outputs[AD_OUT_FAN] = false;
			}
		}

		// Relay outputs
		nxt_outputs[AD_OUT_PI] = man_outputs[AD_OUT_PI];
		nxt_outputs[AD_OUT_FAN] = auto_outputs[AD_OUT_FAN] || man_outputs[AD_OUT_FAN];
		nxt_outputs[AD_OUT_RLY_1] = auto_outputs[AD_OUT_RLY_1] || man_outputs[AD_OUT_RLY_1];
		nxt_outputs[AD_OUT_RLY_2] = auto_outputs[AD_OUT_RLY_2] || man_outputs[AD_OUT_RLY_2];
		nxt_outputs[AD_OUT_RLY_3] = auto_outputs[AD_OUT_RLY_3] || man_outputs[AD_OUT_RLY_3];
		nxt_outputs[AD_OUT_RLY_4] = auto_outputs[AD_OUT_RLY_4] || man_outputs[AD_OUT_RLY_4];
		
		xSemaphoreGive(access_mutex);

		//
		// Evaluate output changes
		//
		if (nxt_outputs[AD_OUT_PI] != cur_outputs[AD_OUT_PI]) {
			cur_outputs[AD_OUT_PI] = nxt_outputs[AD_OUT_PI];
			digitalWrite(AX_IO_PI_EN, cur_outputs[AD_OUT_PI] ? HIGH : LOW);
		}

		if (nxt_outputs[AD_OUT_FAN] != cur_outputs[AD_OUT_FAN]) {
			cur_outputs[AD_OUT_FAN] = nxt_outputs[AD_OUT_FAN];
			digitalWrite(AX_IO_FAN_EN, cur_outputs[AD_OUT_FAN] ? HIGH : LOW);
		}

		for (i=0; i<4; i++) {
			if (nxt_outputs[AD_OUT_RLY_1 + i] != cur_outputs[AD_OUT_RLY_1 + i]) {
				cur_outputs[AD_OUT_RLY_1 + i] = nxt_outputs[AD_OUT_RLY_1 + i];
				KMPProDinoESP32.setRelayState(i, cur_outputs[AD_OUT_RLY_1 + i]);
			}
		}
		
		vTaskDelay(EVAL_MSEC / portTICK_PERIOD_MS);
	}
}

bool AxDinoESP32Class::switchPressed(int i, bool cur)
{
	bool ret = false;
	
	if (!sw_down[i] && sw_prev_inputs[i] && cur) {
		// Press just detected
		ret = true;
	}
	sw_down[i] = sw_prev_inputs[i] && cur;
	sw_prev_inputs[i] = cur;
	
	return ret;
}

