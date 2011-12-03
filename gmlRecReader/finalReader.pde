import controlP5.*;

import org.apache.log4j.PropertyConfigurator;

import toxi.geom.Vec3D;

import gml4u.brushes.*;
import gml4u.drawing.*;
import gml4u.utils.*;
import gml4u.model.*;

Gml gml;
GmlBrushManager brushManager = new GmlBrushManager();

ControlP5 controlP5;

controlP5.ListBox fileList;
controlP5.ListBox brushList;
controlP5.Button modeButton;

String brushStyle;
File[] files;


int mode;


void setup() {
  
  size(800, 800);
  //
  // Controlp5
  //
  controlP5 = new ControlP5(this);

  modeButton = controlP5.addButton("LIST FILES", 0, 10, 10, 50, 20);

  fileList = controlP5.addListBox("myList", 10, 10, 300, 300);
  fileList.setItemHeight(20);
  fileList.setBarHeight(20);

  brushList = controlP5.addListBox("brushList", 10, 80, 300, 300);
  brushList.setItemHeight(20);
  brushList.setBarHeight(20);

  modeButton.setVisible(false);

  int i = 0;
  for (String styleId : brushManager.getStyles()) {
    brushList.addItem(styleId, i);
    i++;
  }

  files = listFiles("/test");  
  for (i = 0; i<files.length; i++) {
    fileList.addItem(files[i].getName(), i);
  }

  fileList.show();
  modeButton.hide();
  brushList.hide();
  //
  // GML
  //
  PropertyConfigurator.configure(sketchPath+"/log4j.properties");
  brushStyle = (String) brushManager.getStyles().toArray()[0];
  //
  mode = 0;
}


void draw() {
  background(255);
  if(mode == 1) {
    brushManager.setDefault(brushStyle);
    //brushManager.draw(this.g, gml, 600.0);
  }
}

void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup()) {

    if (mode == 0) { // files
      print( " OK ");
      mode = 1;
      
      print(files[int(theEvent.group().value())]);
      gml = GmlParsingHelper.getGml(files[int(theEvent.group().value())].getAbsolutePath(), true);
      fileList.hide();
      modeButton.show();
      brushList.show();

    } else { // else it's the brushes
      brushStyle = String.valueOf(theEvent.group().value());
    }

  } else {

      fileList.clear();
      File[] files = listFiles("/test");  
      for (int i = 0; i<files.length; i++) {
        fileList.addItem(files[i].getName(), i);
      }

      fileList.setVisible(true);
      modeButton.setVisible(false);
      brushList.hide();

      mode = 0;
  }
}

File[] listFiles(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } 
  else {
    // If it's not a directory
    return null;
  }
}

void keyPressed() {
}

