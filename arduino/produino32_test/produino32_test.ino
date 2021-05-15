#include <OneWire.h>
#include <DallasTemperature.h>
#include "KMPProDinoESP32.h"
#include "KMPCommon.h"

// GPIO pins
const int sw1 = 35;
const int sw2 = 27;
const int sw3 = 34;
const int sw4 = 25;
const int pi_en = 26;
const int fan_en = 14;

// GPIO where the DS18B20 is connected to
const int oneWireBus = 13;     

// Setup a oneWire instance to communicate with any OneWire devices
OneWire oneWire(oneWireBus);

// Pass our oneWire reference to Dallas Temperature sensor 
DallasTemperature sensors(&oneWire);

int count = 0;

void setup() {
  // Setup the GPIO pins
  pinMode(sw1, INPUT_PULLUP);
  pinMode(sw2, INPUT_PULLUP);
  pinMode(sw3, INPUT_PULLUP);
  pinMode(sw4, INPUT_PULLUP);
  pinMode(pi_en, OUTPUT);
  digitalWrite(pi_en, LOW);
  pinMode(fan_en, OUTPUT);
  digitalWrite(fan_en, LOW);
  
  // Start the Serial Monitor
  Serial.begin(115200);
  // Start the DS18B20 sensor
  sensors.begin();

  // Start the PRODINo ESP32 board
  KMPProDinoESP32.begin(ProDino_ESP32);
}

void loop() {
  // Get Switch inputs
  Serial.print("Switches: ");
  Serial.print((digitalRead(sw1) == LOW) ? "1" : "0");
  Serial.print((digitalRead(sw2) == LOW) ? "1" : "0");
  Serial.print((digitalRead(sw3) == LOW) ? "1" : "0");
  Serial.print((digitalRead(sw4) == LOW) ? "1" : "0");
  Serial.println();
  
  // Get Temperature
  sensors.requestTemperatures(); 
  float temperatureF = sensors.getTempFByIndex(0);
  Serial.print(temperatureF);
  Serial.println("ºF");

  // Toggle Outputs
  switch (count++) {
    case 0:
      KMPProDinoESP32.setStatusLed(yellow);
      KMPProDinoESP32.setRelayState(0, true);
      digitalWrite(pi_en, HIGH);
      break;
    case 1:
      KMPProDinoESP32.setStatusLed(orange);
      KMPProDinoESP32.setRelayState(0, false);
      break;
    case 2:
      KMPProDinoESP32.setStatusLed(red);
      KMPProDinoESP32.setRelayState(1, true);
      break;
    case 3:
      KMPProDinoESP32.setStatusLed(green);
      KMPProDinoESP32.setRelayState(1, false);
      digitalWrite(pi_en, LOW);
      break;
    case 4:
      KMPProDinoESP32.setStatusLed(blue);
      KMPProDinoESP32.setRelayState(2, true);
      digitalWrite(fan_en, HIGH);
      break;
    case 5:
      KMPProDinoESP32.setStatusLed(white);
      KMPProDinoESP32.setRelayState(2, false);
      break;
    case 6:
      KMPProDinoESP32.setStatusLed(black);
      KMPProDinoESP32.setRelayState(3, true);
      break;
    case 7:
      KMPProDinoESP32.setStatusLed(red);
      KMPProDinoESP32.setRelayState(3, false);
      digitalWrite(fan_en, LOW);
      count = 0;
      break;
    default:
      count = 0;
  }
  delay(1000);
}
