
#define SCLK                10
#define SDIO                11
#define RESET_PIN           12
#define NCS                 13
#define POWER               17

#define PRODUCTID          0x00 // should be 0x12
#define PRODUCTID2          0x3e //should be 0x26
#define REVISION_ID         0x01
#define DELTA_Y_REG         0x03
#define DELTA_X_REG         0x04
#define SQUAL_REG           0x05
#define MAXIMUM_PIXEL_REG   0x08
#define MINIMUM_PIXEL_REG   0x0a
#define PIXEL_SUM_REG       0x09
#define PIXEL_DATA_REG      0x0b
#define SHUTTER_UPPER_REG   0x06
#define SHUTTER_LOWER_REG   0x07
#define RESET		    0x3a
#define CPI500v		    0x00
#define CPI1000v	    0x01

#define NUM_PIXELS          360

#define MICROSEC_DELAY      10

byte pix[360];

const int LED_R = 26;
const int LED_L = 24;

void setup()
{
  Serial.begin(115200);

  pinMode(SDIO, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(POWER, OUTPUT);
  
  pinMode(LED_R, OUTPUT);
  pinMode(LED_L, OUTPUT);
  
  digitalWrite(LED_R, HIGH);
  digitalWrite(LED_L, HIGH);

  digitalWrite(POWER, HIGH);

  pinMode(RESET_PIN, OUTPUT);
  digitalWrite(RESET_PIN, HIGH);

  sync();

  ADNS_write(RESET, 0x5a);
  delay(50); // From NRESET pull high to valid mo tion, assuming VDD and motion is present.

}

void loop()
{
  delay(100); 

  //Serial.println( ADNS_read(PRODUCTID2), HEX);

  pixelGrab();
}

void sync()
{
  pinMode(NCS, OUTPUT);
  digitalWrite(NCS, LOW);
  delayMicroseconds(2);
  digitalWrite(NCS, HIGH);
}

void ADNS_write(unsigned char addr, unsigned char data) 
{
  char temp;
  int n;

  digitalWrite(NCS, LOW);//nADNSCS = 0; // select the chip

  temp = addr | 0x80; // MOST RECENT

  digitalWrite(SCLK, LOW); //SCK = 0;					// start clock low
  pinMode(SDIO, OUTPUT); //DATA_OUT; // set data line for output
  for (n=0; n<8; n++) {
    digitalWrite(SCLK, LOW); //SCK = 0;
    pinMode(SDIO, OUTPUT);
    delayMicroseconds(MICROSEC_DELAY);
    if (temp & 0x80)
      digitalWrite(SDIO, HIGH); //SDOUT = 1;
    else
      digitalWrite(SDIO, LOW);//SDOUT = 0;
    temp = (temp << 1);
    digitalWrite(SCLK, HIGH);//SCK = 1;
    delayMicroseconds(MICROSEC_DELAY);//delayMicroseconds(1);			// short clock pulse
  }
  temp = data;
  for (n=0; n<8; n++) {
    delayMicroseconds(MICROSEC_DELAY);
    digitalWrite(SCLK, LOW);//SCK = 0;
    delayMicroseconds(MICROSEC_DELAY);
    if (temp & 0x80)
      digitalWrite(SDIO, HIGH);//SDOUT = 1;
    else
      digitalWrite(SDIO, LOW);//SDOUT = 0;
    temp = (temp << 1);
    digitalWrite(SCLK, HIGH);//SCK = 1;
    delayMicroseconds(1);			// short clock pulse
  }
  delayMicroseconds(20);
  digitalWrite(NCS, HIGH); //nADNSCS = 1; // de-select the chip
}

byte ADNS_read(unsigned char addr)
{
  byte temp;
  int n;

  digitalWrite(NCS, LOW); //nADNSCS = 0;				// select the chip
  temp = addr;
  digitalWrite(SCLK, OUTPUT); //SCK = 0  start clock low
  pinMode(SDIO, OUTPUT); //DATA_OUT set data line for output
  for (n=0; n<8; n++) {
    delayMicroseconds(MICROSEC_DELAY);
    digitalWrite(SCLK, LOW); //SCK = 0;
    delayMicroseconds(MICROSEC_DELAY);
    pinMode(SDIO, OUTPUT); //DATA_OUT;
    if (temp & 0x80) {
      digitalWrite(SDIO, HIGH); //SDOUT = 1;
    } 
    else {
      digitalWrite(SDIO, LOW); //SDOUT = 0;
    }
    delayMicroseconds(MICROSEC_DELAY);
    temp = (temp << 1);
    digitalWrite(SCLK, HIGH); //SCK = 1;
  }

  temp = 0; // This is a read, switch to input
  pinMode(SDIO, INPUT); //DATA_IN;
  for (n=0; n<8; n++) { // read back the data
    delayMicroseconds(MICROSEC_DELAY);
    digitalWrite(SCLK, LOW);
    delayMicroseconds(MICROSEC_DELAY);
    if(digitalRead(SDIO)) { // got a '1'
      temp |= 0x1;
    }
    if( n != 7) temp = (temp << 1); // shift left
    delayMicroseconds(MICROSEC_DELAY);
    digitalWrite(SCLK, HIGH);
  }
  delayMicroseconds(20);
  digitalWrite(NCS, HIGH);// de-select the chip
  return temp;
}

byte ADNS_readPix(unsigned char addr)
{
  byte temp;
  int n;

  digitalWrite(NCS, LOW); //nADNSCS = 0 select the chip
  temp = addr;
  digitalWrite(SCLK, HIGH); //SCK = 0 start clock low
  pinMode(SDIO, OUTPUT); //DATA_OUT set data line for output

  for (n=0; n<8; n++) {
    digitalWrite(SCLK, LOW); //SCK = 0;
    delayMicroseconds(MICROSEC_DELAY);
    if (temp & 0x80) {
      digitalWrite(SDIO, HIGH); //SDOUT = 1;
    } 
    else {
      digitalWrite(SDIO, LOW); //SDOUT = 0;
    }
    temp = (temp << 1);
    //delayMicroseconds(1);
    digitalWrite(SCLK, HIGH); //SCK = 1;
    delayMicroseconds(MICROSEC_DELAY); // short clock pulse
  }

  temp = 0; // This is a read, switch to input

  pinMode(SDIO, INPUT); //DATA_IN;
  for (n=0; n < 7; n++) { // read back the data
    digitalWrite(SCLK, LOW);
    delayMicroseconds(MICROSEC_DELAY);
    if(digitalRead(SDIO)) { // got a '1'
      temp |= 0x1;
    }
    digitalWrite(SCLK, HIGH);
    delayMicroseconds(MICROSEC_DELAY);
    if( n != 6 ) temp = (temp << 1); // shift left
  }

  digitalWrite(NCS, HIGH);// de-select the chip
  return temp;
}

void pixelGrab()
{
  ADNS_write(PIXEL_DATA_REG, 1);
  int grabCount = 0; 
  while( grabCount < NUM_PIXELS )
  {
    Serial.print(ADNS_readPix(PIXEL_DATA_REG), BYTE);
    delay(1);
    grabCount++;
  }
  Serial.write('0');
}






