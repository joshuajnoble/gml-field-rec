
import processing.serial.*;

Serial port;  // Create object from Serial class
int val;      // Data received from the serial port

int ratio;
int ind;
boolean hasRecd;

int[] pix;

void setup() 
{
  
  ind = 0;
  pix = new int[360];
  size(720, 720);
  String portName = Serial.list()[0];
  println( portName );
  port = new Serial(this, portName, 115200);
  
  ratio = 720/18;
  noStroke();
}

void draw()
{
  int i = 0;
  while ( port.available() > 0) {  // If data is available,
    
    int tmp = port.read();

    if(tmp == 0 || ind > 359) {
      hasRecd = true;
      ind = 0;
    } 
    else
    {
      pix[ind] = tmp;
    }
    
    ind++;
    i++;
  }
  
  if(hasRecd) {
    // Set background to white
    background(255);
    i=0;
    int x = 0, y = 0;
    while( i < 360 )
    {
      fill( pix [i] * 2 );
      rect( x, y, ratio, ratio );
      
      if(x == ratio*18) {
        x = 0;
        y += ratio;
      } else {
        x += ratio;
      }
      i++;
    }
    
    hasRecd = false;
    ind = 0;
  }
  
}

