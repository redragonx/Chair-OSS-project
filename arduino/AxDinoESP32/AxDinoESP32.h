//
// Wrapper library for the ProDinoESP32 based wheelchair controller
//
#ifndef _AXDINOESP32_H
#define _AXDINOESP32_H

#include "Arduino.h"
#include "KMPProDinoESP32.h"
#include "Task.h"


//
// Constants
//

// Version String
#define AD_VERSION "2.0"

// Temperature units
#define AD_TEMP_C 0
#define AD_TEMP_F 1

// Output channels
#define AD_OUT_PI    0
#define AD_OUT_FAN   1
#define AD_OUT_RLY_1 2
#define AD_OUT_RLY_2 3
#define AD_OUT_RLY_3 4
#define AD_OUT_RLY_4 5

#define AD_NUM_OUTS  6
#define AD_NUM_INS   4

// Fan default temperature
#define AD_FAN_THRESH 50

// Fan hysteresis (C)
#define AD_FAN_HYST  5



//
// Class Definition
//
class AxDinoESP32Class: public Task
{
public:
	/**
	* @brief Initialize Controller.  Must be called before any other method.
	*
	* @return void
	*/
	void begin();

	/**
	* @brief Get version string.
	*
	* @return pointer to constant version string
	*/
	char* getVersion() {return AD_VERSION;}

	/**
	* @brief Get latest temperature sensor value.
	* @param units Specify temperature units (AD_TEMP_C or AD_TEMP_F)
	*
	* @return Floating point temperature
	*/
	float getTemp(int units);
	
	/**
	* @brief Get automatic fan control temperature threshold
	*
	* @return Temperature threshold in degrees C
	*/
	float getFanAutoTemp();

	/**
	* @brief Enable automatic fan control
	* @param t Temperature threshold
	* @param units Temperature units (AD_TEMP_C or AD_TEMP_F)
	*
	* @return void
	*/
	void setFanAutoTemp(float t, int units);

	/**
	* @brief Get Relay Box switch input value
	* @param n Switch number (0 - 3)
	*
	* @return True if relay closed, False if relay open
	*/
	bool getSwitch(int n);

	/**
	* @brief Set an output channel.  Clearing a channel may not disable the output if
	* enableAutoSwitch is set to true.
	* @param n Channel (AD_OUT_PI, AD_OUT_FAN, AD_OUT_RLY_1, AD_OUT_RLY_2, AD_OUT_RLY_3, AD_OUT_RLY_4)
	* @param State True to enable, False to disable
	*
	* @return void
	*/
	void setOutput(int n, bool state);

	/**
	* @brief Return the status of an output channel based on manual control.
	* @param n Channel (AD_OUT_PI, AD_OUT_FAN, AD_OUT_RLY_1, AD_OUT_RLY_2, AD_OUT_RLY_3, AD_OUT_RLY_4)
	*
	* @return Current state
	*/
	bool getOutput(int n);
	
	/**
	* @brief Return the status of an output channel based on the Relay Box inputs.
	* @param n Channel (AD_OUT_PI, AD_OUT_FAN, AD_OUT_RLY_1, AD_OUT_RLY_2, AD_OUT_RLY_3, AD_OUT_RLY_4).
	*
	* @return Current state
	*/
	bool getAutoOutput(int n);
	
	/**
	* @brief Get automatic control of fan state
	*
	* @return returns True if automatic control is enabled
	*/
	bool getAutoFan();

	/**
	* @brief Enable automatic control of the fan based on the temperature sensor
	* @param state True to enable, False to disable
	*
	* @return void
	*/
	void enableAutoFan(bool state);
	
	/**
	* @brief Get automatic control of the four relays state
	* 
	* @return returns True if automatic control of the relays is enabled
	*/
	bool getAutoSwitch();

	/**
	* @brief enable automatic control of the four relays based on Wheelchair Relay Box inputs
	* @param state True to enable, False to disable
	*
	* @return void
	*/
	void enableAutoSwitch(bool state);

	/**
	* @brief Set the ProDinoESP32 RGB LED
	* @param RGB Color to set
	*
	* @return
	*/
	void setLED(RgbColor color);

private:
	// Task
	void run(void *data);
	
	// Private methods
	
	// Debounce and manage switch state, return true for just pressed
	bool switchPressed(int i, bool cur);

	// Variables
	bool auto_fan;
	bool auto_switch;
	bool sw_inputs[AD_NUM_INS];
	bool sw_prev_inputs[AD_NUM_INS];
	bool sw_down[AD_NUM_INS];
	bool cur_outputs[AD_NUM_OUTS];
	bool auto_outputs[AD_NUM_OUTS];
	bool man_outputs[AD_NUM_OUTS];
	float cur_temp_c;
	float set_temp_c;

	SemaphoreHandle_t access_mutex;
};

extern AxDinoESP32Class AxDinoESP32;

#endif /* _AXDINOESP32_H */
