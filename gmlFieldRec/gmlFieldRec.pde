#include "ADNS5050.h"
#include "GMLWriter.h"
#include <Wire.h>
#include <ADXL345.h>
#include <HMC58X3.h>
#include <ITG3200.h>
#include <CapSense.h>

#include <SdFat.h>

// I'm using a Teensy 2.0, but you can use any 328 or higher board.
// You do need a bigger board to run this, anything with a 168 or Atmega8
// probably isn't going to cut it
#define __AVR_AT90USB1286__
// #define __AVR_ATmega328P__ // Arduino Uno

//#define DEBUG

//#ifdef DEBUG
//  const int CAP_LIM = 2000;
//#else ifndef DEBUG
  const int CAP_LIM = 500;
//#endif

#include "DebugUtils.h"
#include "FreeIMU.h"
#include "CommunicationUtils.h"

#define TAGGING_LED 33
#define SDCARD_LED 29
#define SQUAL_LED 28
#define TAG_PIN 32

#define SCLK                11
#define SDIO                10
#define RESET_PIN           12
#define NCS                 13

#define ILLUMINATION_LED 24
#define LASER_LED 19

// STATE
int state;

#define INIT 1
#define TAGGING 2
#define TAGGING_DOWN 3
#define FINISH_TAG 4

long debounce;

//#define CAN_HEIGHT_600ML 28.4 // height of a 600ML molotow can in CM
//#define CAN_HEIGHT_12OZ 26

//#define CAN_HEIGHT_600ML 14.2 // height of a 600ML molotow can in CM
#define CAN_HEIGHT_600ML 2

ADNS5050 omouse(SCLK, SDIO, NCS, RESET_PIN); // might want to shift this over to non-PWM pins?
GMLWriter gml;

// we'll just start at 2000 so we don't go negative
float position[2] = { 
  2000.0, 2000.0 };
int pposition[2];

float ypr[3] = { 0.0, 0.0, 0.0 };
float prevYpr[3];

// Set the FreeIMU object
FreeIMU imu = FreeIMU();

long tagStart;
int surfQuality;
long lastSurfBlink;
boolean squalPin;

CapSense listenCap = CapSense(34, 30);

void setup()
{

  //Serial.begin( 9600 );
  
  omouse.sync(); // this takes a second
  
  pinMode( LASER_LED, OUTPUT);
  pinMode( ILLUMINATION_LED, OUTPUT );
  pinMode(TAG_PIN, INPUT);

  pinMode(TAGGING_LED, OUTPUT);
  pinMode(SDCARD_LED, OUTPUT);
  pinMode(SQUAL_LED, OUTPUT);

  digitalWrite( SDCARD_LED, HIGH);
  delay(500);
  digitalWrite( SDCARD_LED, LOW);
  digitalWrite( TAGGING_LED, HIGH);
  delay(500);
  digitalWrite( TAGGING_LED, LOW);
  digitalWrite( SQUAL_LED, HIGH);
  delay(500);
  digitalWrite( SQUAL_LED, LOW);

  // SD CARD SET UP
  debounce = millis();

  int ret = gml.init();
  //Serial.print( ret );
  if(ret != 1) { // i.e. if it fails

    //Serial.println(" GML not intialized ");

    int i;
    for(i = 0; i<5; i++) { // 5 blinks = not ok
      digitalWrite( SDCARD_LED, HIGH);
      delay(250);
      digitalWrite( SDCARD_LED, LOW);
      delay(250);
    }
  } 
  else {
    digitalWrite( SDCARD_LED, HIGH);
    delay(2000);
    digitalWrite( SDCARD_LED, LOW);
  }

  state = INIT;
  
  // CAPSENSE setup
  listenCap.set_CS_Timeout_Millis(30);
  listenCap.set_CS_AutocaL_Millis(10);
  
  
  // FREEIMU set up
  Wire.begin();
  //Serial.println( " set pu  ");
  delay(5);
  imu.init(); // the parameter enable or disable fast mode
  delay(5);
}


void loop()
{

  if(state == INIT)
  {
    if(digitalRead(TAG_PIN) && millis() - debounce > 500) {

      debounce = millis();

      //Serial.println(" start tagging ");

      if( gml.beginDrawing() != 1 ) {
        
        //Serial.print(" can't begin drawing ");
        
        int i;
        for(i = 0; i<5; i++) { // 5 blinks = not ok
          digitalWrite( SDCARD_LED, HIGH);
          delay(500);
          digitalWrite( SDCARD_LED, LOW);
          delay(500);
        }
        return;
      }

      state = TAGGING;
      
      digitalWrite(TAGGING_LED, HIGH); // know you're tagging
      digitalWrite( ILLUMINATION_LED, HIGH );
      digitalWrite( LASER_LED, HIGH);

      return;
    }
  }
  else if (state == TAGGING)
  {
    //delay(10);
    ////Serial.println(" TAGGING ");
    tagStart = millis();

    if(digitalRead(TAG_PIN) && millis() - debounce > 500) {
      debounce = millis();
      //Serial.println(" tag pin ");
      state = FINISH_TAG;
    }
   
   byte sqty = omouse.surfaceQuality();
   if(sqty != -1) { // sometimes this just returns nothing
     surfQuality = 80 - (sqty * 4);
   }
   
    if(surfQuality < 2) {
      digitalWrite(SQUAL_LED, HIGH);
    } else if(millis() - lastSurfBlink > surfQuality) {
      lastSurfBlink = millis();
      digitalWrite(SQUAL_LED, squalPin);
      squalPin = !squalPin;
    }
    

    imu.getYawPitchRoll(ypr);
    determinePosition();
    
    int cap = listenCap.capSense(10);
    if(cap > CAP_LIM || cap < -1) // this is for my configuration, yrs may differ
    {
      digitalWrite(SDCARD_LED, HIGH);
      state = TAGGING_DOWN;
      gml.beginStroke();
    }
    
  }
  else if (state == TAGGING_DOWN)
  {
    determinePosition();

    ////Serial.println( omouse.surfaceQuality(), DEC );
    
   byte sqty = omouse.surfaceQuality();
   if(sqty > 0) { // sometimes this just returns nothing
     surfQuality = 80 - (sqty * 4);
   }
    
    if(surfQuality < 2) {
      digitalWrite(SQUAL_LED, HIGH);
    } else if(millis() - lastSurfBlink > surfQuality) {
      lastSurfBlink = millis();
      digitalWrite(SQUAL_LED, squalPin);
      squalPin = !squalPin;
    }
    
    int cap = listenCap.capSense(10);
    if(cap > CAP_LIM || cap < 0)
    {

      if( abs(pposition[0] - position[0]) > 1.0 ||  abs(pposition[1] - position[1]) > 1.0) {
        gml.addPoint(position[0], position[1], millis() - tagStart);
      }

      pposition[0] = position[0];
      pposition[1] = position[1];

    }
    else
    {
      digitalWrite(SDCARD_LED, LOW);
      debounce = millis();
      state = TAGGING;
      gml.endStroke();

    }
    
  }
  else if(state == FINISH_TAG)
  {
    //if(gml.endDrawing()) {

    digitalWrite( ILLUMINATION_LED, LOW );
    digitalWrite( LASER_LED, LOW);

    if(gml.endDrawing()) {

      //Serial.println(" FINISH_TAG OK ");

      digitalWrite(TAGGING_LED, LOW); // know you're tagging
      digitalWrite( SDCARD_LED, HIGH);
      delay(1000);
      digitalWrite( SDCARD_LED, LOW);
      delay(500);
      digitalWrite( SDCARD_LED, HIGH);
      delay(1000);
      digitalWrite( SDCARD_LED, LOW); // 2 blinks, it's ok


    } else {

      //Serial.println(" FINISH_TAG NOT OK ");

      digitalWrite(TAGGING_LED, LOW); // know you're tagging

      int i;
      for(i = 0; i<5; i++) { // 5 blinks = not ok
        digitalWrite( SDCARD_LED, HIGH);
        delay(500);
        digitalWrite( SDCARD_LED, LOW);
        delay(500);
      }
    }
    digitalWrite( SQUAL_LED, LOW);
    state = INIT;
  }
}

void determinePosition()
{

  position[0] -= omouse.dx() >> 1;
  position[1] -= omouse.dy() >> 1;

  float y, p, r;

  imu.getYawPitchRoll(&ypr[0]);

  y = prevYpr[0] - ypr[0];
  p = prevYpr[1] - ypr[1];
  r = prevYpr[2] - ypr[2];
  
  float xRot, yRot;

  if(abs(p) > 0.1) /// some arbitrary noise amount
  {
    //xRot = sin(ypr[1] * (PI/180.0) + (TWO_PI));
    //yRot = cos(ypr[1] * (PI/180.0) + (TWO_PI));

    xRot = sin(ypr[1] + (TWO_PI)) * CAN_HEIGHT_600ML;
    yRot = cos(ypr[1] + (TWO_PI)) * CAN_HEIGHT_600ML;
    
    position[0] -= xRot;
    position[1] -= yRot;
    
  }

  prevYpr[0] = ypr[0];
  prevYpr[1] = ypr[1];
  prevYpr[2] = ypr[2];

  /*Serial.print(ypr[1]);
  //Serial.print(" ");
  //Serial.print(position[0]);
  //Serial.print(" " );
  //Serial.println(position[1]);*/

}


