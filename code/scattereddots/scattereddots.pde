// Processing code by Etienne Jacob
// motion blur template by beesandbombs
// See the license information at the end of this file.
// result here : https://bleuje.com/gifanimationsite/single/scattereddots/

int[][] result;
float t, c;

float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
}

void draw() {

  if (!recording) {
    t = (mouseX*1.3/width)%1;
    c = mouseY*1.0/height;
    if (mousePressed)
      println(c);
    draw_();
  } else {
    for (int i=0; i<width*height; i++)
      for (int a=0; a<3; a++)
        result[i][a] = 0;

    c = 0;
    for (int sa=0; sa<samplesPerFrame; sa++) {
      t = map(frameCount-1 + sa*shutterAngle/samplesPerFrame, 0, numFrames, 0, 1);
      t %= 1;
      draw_();
      loadPixels();
      for (int i=0; i<pixels.length; i++) {
        result[i][0] += pixels[i] >> 16 & 0xff;
        result[i][1] += pixels[i] >> 8 & 0xff;
        result[i][2] += pixels[i] & 0xff;
      }
    }

    loadPixels();
    for (int i=0; i<pixels.length; i++)
      pixels[i] = 0xff << 24 | 
        int(result[i][0]*1.0/samplesPerFrame) << 16 | 
        int(result[i][1]*1.0/samplesPerFrame) << 8 | 
        int(result[i][2]*1.0/samplesPerFrame);
    updatePixels();
    
    if (frameCount<=numFrames)
    {
      saveFrame("fr###.gif");
      println(frameCount,"/",numFrames);
    }
    
    if (frameCount==numFrames)
      stop();
  }
}


// end of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 5;
int numFrames = 200;        
float shutterAngle = 1.0;

boolean recording = false;

// IDEA : just a single path made from a precomputed list of positions
// with dots following it with replacement technique

int numberOfJumps = 200; // number of "jumps" / position changes in one path
int K = 60; // number of dots on path with replacement technique
float emptyMargin = 100; // to keep the path in the center

class DotPath
{
  // start position of the path
  float startX = random(emptyMargin, width-emptyMargin);
  float startY = random(emptyMargin, height-emptyMargin);
  
  // filled from simulation in constructor
  ArrayList<PVector> positions = new ArrayList<PVector>();
  ArrayList<Float> sizes = new ArrayList<Float>();
  
  DotPath()
  {
    float x = startX;
    float y = startY;
    positions.add(new PVector(x,y));
    
    sizes.add(0.0); // start with a size 0
    
    for(int i=0;i<numberOfJumps;i++)
    {
      float jumpLength = random(25,150);
      int choice = floor(random(0,8)); // 8 possible directions (vertical/horizontal/diagonal)
      
      if(choice==0){
        x += jumpLength;
      }
      if(choice==1){
        x -= jumpLength;
      }
      if(choice==2){
        y += jumpLength;
      }
      if(choice==3){
        y -= jumpLength;
      }
      if(choice==4){
        x += jumpLength;
        y += jumpLength;
      }
      if(choice==5){
        x -= jumpLength;
        y += jumpLength;
      }
      if(choice==6){
        x += jumpLength;
        y -= jumpLength;
      }
      if(choice==7){
        x -= jumpLength;
        y -= jumpLength;
      }
      
      // mirror jump if in margin
      if(x>width-emptyMargin){
        x -= 2*jumpLength;
      }
      if(x<emptyMargin){
        x += 2*jumpLength;
      }
      if(y>height-emptyMargin){
        y -= 2*jumpLength;
      }
      if(y<emptyMargin){
        y += 2*jumpLength;
      }
      
      positions.add(new PVector(x, y));
      
      if(i==numberOfJumps-1)
      {
        sizes.add(0.0); // size 0 on last step
      }
      else
      {
        sizes.add(random(1,3));
      }
    }
    
    // at the end, the lists positions and sizes have numberOfJumps+1 elements
  }
  
  // Interpolating between already computed steps (https://bleuje.com/tutorial7/)
  void show(float p)
  {
    float floatIndex = p*numberOfJumps*0.9999;
    int i1 = floor(floatIndex);
    int i2 = i1+1;
    float lerpParameter = floatIndex-i1;
    lerpParameter = ease(lerpParameter,4.0); // easing between two positions of the simulation
    // 4.0 is a strong value, that's why dots seem to stop
    
    // position
    PVector pos1 = positions.get(i1);
    PVector pos2 = positions.get(i2);
    float X = lerp(pos1.x, pos2.x, lerpParameter);
    float Y = lerp(pos1.y, pos2.y, lerpParameter);
    
    // dot size
    Float size1 = sizes.get(i1);
    Float size2 = sizes.get(i2);
    float dotSize = lerp(size1, size2, lerpParameter);
    
    stroke(255);
    strokeWeight(dotSize);
    point(X,Y);
  }
  
  
  // replacement technique
  void showReplacement()
  {
    for(int i=0;i<K;i++)
    {
      float p = (i+t)/K;
      show(p);
    }
  }
}

DotPath dotPath;

void setup(){
  size(500,500,P2D);
  result = new int[width*height][3];
  
  smooth(8);
  randomSeed(234);
  
  dotPath = new DotPath();
}

void draw_(){
  background(0);
  
  dotPath.showReplacement();
}

/* License:
 *
 * Copyright (c) 2018, 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
