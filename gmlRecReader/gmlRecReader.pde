import controlP5.*;


// select the disk to browse from
// get a list of the files on it
// select from those files which ones to import
// and parse, then delete them when you're done

ControlP5 ctrl;

Textfield diskToBrowse;
Button browse;


void setup()
{
  
  ctrl = new ControlP5(this);
  diskToBrowse.setFocus(true);
  ctrl.addTextufield("disk", 100, 200, 100, 20);
  ctrl.addButton("Load", 100, 100, 400, 20);
  
}


void draw()
{
  background(0);
  
}


void parse()
{
  
  // find max&min x&y
  // parse back into the file
  // have to normalize all the coordinates
  
  float minx, miny, maxx, maxy;
  
  while()
  {
    if( x 
  }
  
}
