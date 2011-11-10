#include "ADNS5050.h"
#include "GMLWriter.h"
#include <Wire.h>
#include <ADXL345.h>
#include <HMC58X3.h>
#include <ITG3200.h>

#include <SdFat.h>

// I'm using a Teensy 2.0, but you can use any 328 or higher board.
// You do need a bigger board to run this, anything with a 168 or Atmega8
// probably isn't going to cut it
#define __AVR_AT90__ 
// #define __AVR_ATmega328P__ // Arduino Uno

#define DEBUG

//#define DEBUG
#include "DebugUtils.h"
#include "FreeIMU.h"
#include "CommunicationUtils.h"

#define TAGGING_LED 8
#define SDCARD_LED 9
#define TAG_PIN 15
#define DOWN_PIN 16
#define POWER 17

#define LASER_1 24
#define LASER_2 26
#define ILLUMINATION_LED 25

int state;

#define INIT 1
#define TAGGING 2
#define TAGGING_DOWN 3
#define FINISH_TAG 4

long debounce;

#define CAN_HEIGHT_600ML 28.4 // height of a 600ML molotow can in CM
#define CAN_HEIGHT_12OZ 26

ADNS5050 omouse(10, 11, 12, 13); // might want to shift this over to non-PWM pins?
GMLWriter gml;

int position[2];
float ypr[3];
float prevYpr[3];

// Set the FreeIMU object
FreeIMU imu = FreeIMU();

long tagStart;

void setup()
{
  
  Serial.begin( 9600 );
  
  Serial.println( " begin ");
  
  pinMode(POWER, OUTPUT);
  digitalWrite(POWER, HIGH);
  
  pinMode(TAG_PIN, INPUT);
  pinMode(DOWN_PIN, INPUT);

  pinMode( LASER_1, OUTPUT );
  pinMode( LASER_2, OUTPUT );
  pinMode( ILLUMINATION_LED, OUTPUT );

  pinMode(TAGGING_LED, OUTPUT);
  pinMode(SDCARD_LED, OUTPUT);

  Serial.println( " init GML ");

  debounce = millis();

  
  if(gml.init() != 1) { // i.e. if it fails
    
    Serial.println(" GML not intialized ");
  
    int i;
    for(i = 0; i<5; i++) { // 5 blinks = not ok
      digitalWrite( SDCARD_LED, HIGH);
      delay(500);
      digitalWrite( SDCARD_LED, LOW);
      delay(500);
    }
  }

  state = INIT;
  Serial.println(" INIT ");
}


void loop()
{

  if(state == INIT)
  {
    
    if(digitalRead(TAG_PIN) && millis() - debounce > 500) {
      
      debounce = millis();
      
      Serial.println(" start tagging ");
      
      state = TAGGING;
      omouse.sync(); // this takes a second
      gml.beginDrawing();
      digitalWrite(TAGGING_LED, HIGH); // know you're tagging

      digitalWrite( LASER_1, HIGH );
      digitalWrite( LASER_2, HIGH );
      digitalWrite( ILLUMINATION_LED, HIGH );

      tagStart = millis();
      return;
    }
  }
  else if (state == TAGGING)
  {

    Serial.println(" TAGGING ");
    
    if(digitalRead(TAG_PIN) && millis() - debounce > 500) {
      debounce = millis();
      Serial.println(" tag pin ");
      state = FINISH_TAG;
    }
    
    imu.getYawPitchRoll(ypr);
    determinePosition();
 
    if(digitalRead(DOWN_PIN) && millis() - debounce > 500)
    {
      debounce = millis();
      digitalWrite(SDCARD_LED, HIGH);
      state = TAGGING_DOWN;
      gml.beginStroke();
    }
  }
  else if (state == TAGGING_DOWN)
  {
    Serial.println(" TAGGING_DOWN ");
    determinePosition();

    if(!digitalRead(DOWN_PIN))
    {
      digitalWrite(SDCARD_LED, LOW);
      debounce = millis();
      state = TAGGING;
      gml.endStroke();
    }
    else
    {
      gml.addPoint(position[0], position[1], millis() - tagStart);
    }
  }
  else if(state == FINISH_TAG)
  {
    //if(gml.endDrawing()) {
      
    digitalWrite( LASER_1, LOW );
    digitalWrite( LASER_2, LOW );
    digitalWrite( ILLUMINATION_LED, LOW );
      
    if(gml.endDrawing()) {
      
      Serial.println(" FINISH_TAG OK ");

      digitalWrite(TAGGING_LED, LOW); // know you're tagging
      digitalWrite( SDCARD_LED, HIGH);
      delay(1000);
      digitalWrite( SDCARD_LED, LOW);
      delay(500);
      digitalWrite( SDCARD_LED, HIGH);
      delay(1000);
      digitalWrite( SDCARD_LED, LOW); // 2 blinks, it's ok
      

    } else {
      
      Serial.println(" FINISH_TAG NOT OK ");
      
      digitalWrite(TAGGING_LED, LOW); // know you're tagging

      int i;
      for(i = 0; i<5; i++) { // 5 blinks = not ok
        digitalWrite( SDCARD_LED, HIGH);
        delay(500);
        digitalWrite( SDCARD_LED, LOW);
        delay(500);
      }
    }
    
    state = INIT;
  }
}

void determinePosition()
{
  float y, p, r;

  imu.getYawPitchRoll(ypr);

  y = prevYpr[0] - ypr[0];
  p = prevYpr[1] - ypr[1];
  r = prevYpr[2] - ypr[2];

  if(abs(r) > 0.1) /// some arbitrary noise amount
  {
    position[0] += cos(r) * CAN_HEIGHT_600ML;
    position[1] += sin(r) * CAN_HEIGHT_600ML;
  }

  position[0] += omouse.dx();
  position[1] += omouse.dy();

  // not sure what to do about the yp

}

