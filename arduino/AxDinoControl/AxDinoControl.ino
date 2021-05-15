/*
 * AxDinoESP32 Initial control program
 * 
 */
#include "AxDinoESP32.h"
#include "BluetoothSerial.h"



// ============================
// Constants
//

#define VERSION "1.1"

// Command processor
#define CMD_ST_IDLE 0
#define CMD_ST_CMD  1
#define CMD_ST_ARG  2

#define TERM_CHAR 0x0D

// Error codes
#define ERR_ILL_CMD  1
#define ERR_ILL_IND  2
#define ERR_CMD_RO   3

// Number of "Pi" variables
#define NUM_PI_VARS  10


// Help Contents
static const char* help_string = \
"Command Interface:\n\r" \
"  A<I>/A<I>=<N> : Auto Enable (0: Fan, 1: Relays)\n\r" \
"  H             : Help\n\r" \
"  P<I>/P<I>=<N> : Pi Variable (I = 0 - 9)\n\r" \
"  O<I>/O<I>=<N> : Output (0: Pi, 1: Fan, 2-5: Relays)\n\r" \
"  T<I>/T<I>=<N> : Temperature (0: Fan (RO), 1: SetPoint)\n\r" \
"  S<I>          : Auto Outputs (0: Pi, 1: Fan, 2-5: Relays)\n\r" \
"  V             : Version\n\r";



// ============================
// Variables
//

// Bluetooth serial interface
BluetoothSerial SerialBT;

// Command processor
int CmdState[2];
char CurCmd[2];
uint16_t CmdIndex[2];
uint16_t CmdArg[2];
boolean CmdHasArg[2];

// "Pi" variabels
int PiVars[NUM_PI_VARS];



// ============================
// Arduinio entry points
//

void setup()
{
  int i;
  
  Serial.begin(115200);
  SerialBT.begin("AxDino");
  AxDinoESP32.begin();

  for (i=0; i<NUM_PI_VARS; i++) {
    PiVars[i] = 0;
  }
}


void loop()
{
  char c;

  // Evaluate the serial enable
  if (Serial.available()) {
    c = Serial.read();
    EvalCommand(c, 0);
  }
  
  if (SerialBT.available()) {
    c = SerialBT.read();
    EvalCommand(c, 1);
  }

  if ((CmdState[0] == CMD_ST_IDLE) && (CmdState[1] == CMD_ST_IDLE)) {
    // Delay to allow task scheduling while idle
    delay(40);
  }
}



// ============================
// Subroutines
//

void EvalCommand(char c, int s)
{
    
      switch (CmdState[s]) {
        case CMD_ST_IDLE:
          if (ValidateCommand(c)) {
            CurCmd[s] = c;
            CmdIndex[s] = 0;
            CmdHasArg[s] = false;
            CmdState[s] = CMD_ST_CMD;
          }
          break;
        
        case CMD_ST_CMD:
          if (c == '=') {
            CmdArg[s] = 0;
            CmdState[s] = CMD_ST_ARG;
            CmdHasArg[s] = true;
          } else if (c == TERM_CHAR) {
            ProcessCommand(s);
            CmdState[s] = CMD_ST_IDLE;
          } else if ((c >= '0') && (c <= '9')) {
            CmdIndex[s] = CmdIndex[s]*10 + (c - '0');
          }
          break;
        
        case CMD_ST_ARG:
          if (c == TERM_CHAR) {
            ProcessCommand(s);
            CmdState[s] = CMD_ST_IDLE;
          } else if ((c >= '0') && (c <= '9')) {
            CmdArg[s] = CmdArg[s]*10 + (c - '0');
          }
          break;

        default:
          CmdState[s] = CMD_ST_IDLE;
      }
}


boolean ValidateCommand(char c)
{
  switch (c) {
    case 'A':
    case 'H':
    case 'P':
    case 'O':
    case 'T':
    case 'S':
    case 'V':
      return true;
      break;
    
    default:
      return false;
  }
}


void ProcessCommand(int s)
{
  bool b;
  int rsp;
  
  switch (CurCmd[s]) {
    case 'A':
      if (CmdHasArg[s]) {
        b = (CmdArg[s] == 0) ? false : true;
        if (CmdIndex[s] == 0) {
          AxDinoESP32.enableAutoFan(b);
        } else if (CmdIndex[s] == 1) {
          AxDinoESP32.enableAutoSwitch(b);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      } else {
        if (CmdIndex[s] == 0) {
          rsp = AxDinoESP32.getAutoFan();
          PrintResponse(s, rsp);
        } else if (CmdIndex[s] == 1) {
          rsp = AxDinoESP32.getAutoSwitch();
          PrintResponse(s, rsp);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      }
      break;

    case 'H':
      if (CmdHasArg[s]) {
        DisplayError(s, ERR_CMD_RO);
      } else {
        CommandHelp(s);
      }
      break;

    case 'P':
      if (CmdHasArg[s]) {
        if (CmdIndex[s] < NUM_PI_VARS) {
          PiVars[CmdIndex[s]] = CmdArg[s];
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      } else {
        if (CmdIndex[s] < NUM_PI_VARS) {
          PrintResponse(s, PiVars[CmdIndex[s]]);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      }
      break;
    
    case 'O':
      if (CmdHasArg[s]) {
        if ((CmdIndex[s] >= AD_OUT_PI) && (CmdIndex[s] <= AD_OUT_RLY_4)) {
          b = (CmdArg[s] == 0) ? false : true;
          AxDinoESP32.setOutput(CmdIndex[s], b);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      } else {
        if ((CmdIndex[s] >= AD_OUT_PI) && (CmdIndex[s] <= AD_OUT_RLY_4)) {
          rsp = AxDinoESP32.getOutput(CmdIndex[s]);
          PrintResponse(s, rsp);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      }
      break;
    
    case 'T':
      if (CmdHasArg[s]) {
        if (CmdIndex[s] == 1) {
          AxDinoESP32.setFanAutoTemp(CmdArg[s], AD_TEMP_C);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      } else {
        if (CmdIndex[s] == 0) {
          rsp = round(AxDinoESP32.getTemp(AD_TEMP_C));
          PrintResponse(s, rsp);
        } else if (CmdIndex[s] == 1) {
          rsp = round(AxDinoESP32.getFanAutoTemp());
          PrintResponse(s, rsp);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      }
      break;

    case 'S':
      if (CmdHasArg[s]) {
        DisplayError(s, ERR_CMD_RO);
      } else {
        if ((CmdIndex[s] >= AD_OUT_PI) && (CmdIndex[s] <= AD_OUT_RLY_4)) {
          rsp = AxDinoESP32.getAutoOutput(CmdIndex[s]);
          PrintResponse(s, rsp);
        } else {
          DisplayError(s, ERR_ILL_IND);
        }
      }
      break;

    case 'V':
      if (CmdHasArg[s]) {
        DisplayError(s, ERR_CMD_RO);
      } else {
        if (s == 0) {
          Serial.print("V = ");
          Serial.println(VERSION);
        } else {
          SerialBT.print("V = ");
          SerialBT.println(VERSION);
        }
      }
      break;

    default:
      DisplayError(s, ERR_ILL_CMD);
  }
}


void PrintResponse(int src, int rsp)
{
  if (src == 0) {
    Serial.print(CurCmd[src]);
    Serial.print(" ");
    Serial.print(CmdIndex[src]);
    Serial.print(" = ");
    Serial.println(rsp);
  } else {
    SerialBT.print(CurCmd[src]);
    SerialBT.print(" ");
    SerialBT.print(CmdIndex[src]);
    SerialBT.print(" = ");
    SerialBT.println(rsp);
  }
}


void DisplayError(int src, int errNum)
{
  if (src == 0) {
    Serial.print(F("E"));
    Serial.print(" ");
    Serial.println(errNum);
  } else {
    SerialBT.print(F("E"));
    SerialBT.print(" ");
    SerialBT.println(errNum);
  }
}


void CommandHelp(int src)
{
  if (src == 0) {
    Serial.print(help_string);
    Serial.print("Program Version ");
    Serial.println(VERSION);
    Serial.print("Library Version ");
    Serial.println(AxDinoESP32.getVersion());
  } else {
    SerialBT.print(help_string);
    SerialBT.print("Program Version ");
    SerialBT.println(VERSION);
    SerialBT.print("Library Version ");
    SerialBT.println(AxDinoESP32.getVersion());
  }
}
