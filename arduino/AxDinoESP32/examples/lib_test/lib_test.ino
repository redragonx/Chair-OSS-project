#include "AxDinoESP32.h"



void setup() {
  int i;
  
  Serial.begin(115200);
  AxDinoESP32.begin();
  Serial.print("AxDinoESP32 version ");
  Serial.println(AxDinoESP32.getVersion());

  // Toggle each relay "on"
  for (i=AD_OUT_RLY_1; i<= AD_OUT_RLY_4; i++) {
    AxDinoESP32.setOutput(i, true);
    delay(1000);
  }

  // Toggle each relay "off"
  for (i=AD_OUT_RLY_1; i<= AD_OUT_RLY_4; i++) {
    AxDinoESP32.setOutput(i, false);
    delay(1000);
  }
}

void loop() {
  static int cnt = 0;
  int i;

  // Get Temp
  Serial.print(" Temp: ");
  Serial.print(AxDinoESP32.getTemp(AD_TEMP_F));
  Serial.print("°F ");

  // Auto Outputs
  Serial.print(" Auto Outputs: ");
  for (i=0; i<AD_NUM_OUTS; i++) {
    if (i == AD_OUT_PI) {
      Serial.print("Pi: ");
    }
    if (i == AD_OUT_FAN) {
      Serial.print("Fan: ");
    }
    if (i == AD_OUT_RLY_1) {
      Serial.print("Relays: ");
    }

    Serial.print(AxDinoESP32.getAutoOutput(i) ? "1 " : "0 ");
  }

  // Outputs
  Serial.print(" Outputs: ");
  for (i=0; i<AD_NUM_OUTS; i++) {
    if (i == AD_OUT_PI) {
      Serial.print("Pi: ");
    }
    if (i == AD_OUT_FAN) {
      Serial.print("Fan: ");
    }
    if (i == AD_OUT_RLY_1) {
      Serial.print("Relays: ");
    }

    Serial.print(AxDinoESP32.getOutput(i) ? "1 " : "0 ");
  }

  // Newline after all information for this step printed
  Serial.println();

  // RGB LED "canned" colors (color definitions from KMPProDinoESP32.h)
  switch (cnt++) {
    case 0:
      AxDinoESP32.setLED(red);
      break;
    
    case 1:
      AxDinoESP32.setLED(orange);
      break;
    
    case 2:
      AxDinoESP32.setLED(yellow);
      break;
    
    case 3:
      AxDinoESP32.setLED(green);
      break;
    
    case 4:
      AxDinoESP32.setLED(blue);
      break;
    
    case 5:
      AxDinoESP32.setLED(white);
      break;
    
    case 6:
      AxDinoESP32.setLED(black);
      cnt = 0;
      if (AxDinoESP32.getAutoOutput(AD_OUT_PI)) {
        AxDinoESP32.setOutput(AD_OUT_PI, false);
      }
      break;
  }

  delay(1000);
}
