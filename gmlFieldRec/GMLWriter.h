/*
 *  gml_writer.h
 *  
 *
 *  Created by base on 30/09/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef GML_WRITER
#define GML_WRITER

#include "WProgram.h"
#include "SdFat.h"

class GMLWriter {

public:

  GMLWriter(); 
  ~GMLWriter();

  int init();

  int beginDrawing();
  int endDrawing();

  void beginStroke();
  void endStroke();

  void addPoint( float x, float y, float time );
  void addPoint( float x, float y, float z, float time );
  void addPoint( float x, float y, float z, float time, float rotation );

  int getAsString(char *pt, int len);

private:


  char *storage;
  size_t position, size;
  SdFat sd;

  char * floatToString(char * outstr, float value, int places, int minwidth=0, bool rightjustify=false);

  static const char tagBegin[138];
  static const char tagEnd[23];
  
  SdFile file;
  int readCount;

  //drawingCnt; // don't overwrite shit already on the card

};

#endif

