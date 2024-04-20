// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

//-----------------------------------
// some generally useful functions...

float c01(float x)
{
  return constrain(x,0,1);
}

PVector rotZ(PVector v,float theta)
{
  float x = v.x*cos(theta) - v.y*sin(theta);
  float y = v.x*sin(theta) + v.y*cos(theta);
  return new PVector(x,y,v.z);
}

PVector rotY(PVector v,float theta)
{
  float x = v.x*cos(theta) - v.z*sin(theta);
  float z = v.x*sin(theta) + v.z*cos(theta);
  return new PVector(x,v.y,z);
}

PVector rotX(PVector v,float theta)
{
  float y = v.y*cos(theta) - v.z*sin(theta);
  float z = v.y*sin(theta) + v.z*cos(theta);
  return new PVector(v.x,y,z);
}
//-----------------------------------

void draw()
{
  if (!recording) // test mode...
  { 
    t = (mouseX*1.3/width)%1;
    c = mouseY*1.0/height;
    if (mousePressed)
      println(c);
    draw_();
  }
  else // render mode...
  { 
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
        result[i][0] += red(pixels[i]);
        result[i][1] += green(pixels[i]);
        result[i][2] += blue(pixels[i]);
      }
    }

    loadPixels();
    for (int i=0; i<pixels.length; i++)
      pixels[i] = 0xff << 24 | 
        int(result[i][0]*1.0/samplesPerFrame) << 16 | 
        int(result[i][1]*1.0/samplesPerFrame) << 8 | 
        int(result[i][2]*1.0/samplesPerFrame);
    updatePixels();
    
    if (frameCount<=numFrames) {
      saveFrame("data/fr###.gif");
      println(frameCount,"/",numFrames);
    }
    
    if (frameCount==numFrames)
      stop();
  }
}

// End of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 8;
int numFrames = 330;        
float shutterAngle = 0.8;

boolean recording = false;

PFont mono;

int numberOfDigits = 210; // number of digits
float R = 125; // sphere size/radius

// Important note: the 3D in this code is done with self-made projection, this is using P2D
// I sometimes do this to use transparency easily in 3D for example

float cameraZ()
{
  return 300.0;
}

PVector positionTransform(PVector v)
{
  PVector res;
  res = rotZ(v.copy(), 0.17 * PI + 0.03 * PI * sin(TAU*(t-0.3))); // tilted look of the spehere, with slight change through time
  return res;
}

float projectionFactor = 440.0; // controls the "projection zoom", more zoom if increased

void showParticle(PVector position,float sizeFactor,boolean isDigit,int digitValue,float alphaFactor)
{
  position = positionTransform(position);
 
  float alphaFactor2 = map(position.z,-R,R,0.45,1.3) * alphaFactor;
  
  float zDistanceFromCamera = cameraZ() - position.z;
  if(zDistanceFromCamera > 0)
  {
    // 3D -> 2D projection formula
    float x2D = projectionFactor * position.x / zDistanceFromCamera;
    float y2D = projectionFactor * position.y / zDistanceFromCamera;
    
    PVector pixelPosition = new PVector(x2D,y2D);

    if(isDigit)
    {
      float textSz = 29;
      float scl = 0.1 * sizeFactor * projectionFactor / zDistanceFromCamera; // size change due to the 3D -> 2D projection
    
      push();
      translate(pixelPosition.x -0.5*textSz/2, pixelPosition.y + 0.5*textSz/2); // slight correction translate
      scale(scl);
      rotate(0.03 * sin(TAU*(t-0.3)) * PI); // slight 2D rotation
      
      fill(255,alphaFactor2 * 275);
      noStroke();
      textSize(textSz);
      
      text(digitValue,0,0);
      
      pop();
    }
    else // simple dot, used for dashed curve drawing
    {
      float sz = sizeFactor * projectionFactor / zDistanceFromCamera; // size change due to the 3D -> 2D projection
      
      stroke(255,21 * alphaFactor2);
      strokeWeight(sz);
    
      point(pixelPosition.x,pixelPosition.y);
    }
  }
}

void showDashedCurve()
{
  int dashParam = 20; // number of dots on each segment of the curve
  
  float R2 = 1.05*R; // larger sphere radius for dashed curve

  int m = 1000;
  for(int i=0;i<m;i++)
  {
    if(i%(2*dashParam) > dashParam) continue; // technique to skip drawing half of the time...
    
    // spherical coordinates
    float theta = map((i + 38 * t * float(dashParam)) % m, 0, m, 0, PI); // theta movement, with loop (%m)
    float phi = (t + 0.006) * TAU;
    
    // cartesian coordiantes from spherical coordinates
    float x = R2*sin(theta)*cos(phi);
    float y = R2*cos(theta);
    float z = R2*sin(theta)*sin(phi);
    
    PVector pos = new PVector(x,y,z);
    float sizeFactor = 0.73;
    boolean isDigit = false;
    float alphaFactor = 14.0;
    
    showParticle(pos, sizeFactor, isDigit, 0, alphaFactor);
  }
  
  
  // drawing the big dots at the sphere poles...
  PVector pole1Position = new PVector(0,R2,0);
  PVector pole2Position = new PVector(0,-R2,0);
  showParticle(pole1Position, 4, false, 0, 1000);
  showParticle(pole2Position, 4, false, 0, 1000);
}

class Digit
{
  PVector position0;
  int digitValue;
  
  Digit(int i)
  {
    digitValue = i%10;
    
    // setting (x,y,z) position on black sphere (position at start and end)
    // using special formulas to get evenly distributed positions
    // see https://stackoverflow.com/a/26127012
    float phi = PI * (3. - sqrt(5.));
    float theta = phi*i;
    float y = map(i,0,numberOfDigits-1,1,-1);
    float radius = sqrt(1 - y * y);
    y *= R;
    float x = cos(theta) * R * radius;
    float z = sin(theta) * R * radius;
    
    position0 = new PVector(x,y,z);
  }
  
  void show(float p) // p is the progress parameter in [0,1]
  {
    float delayFromAngle = atan2(position0.z,position0.x)/TAU;
    
    // without the replacement technique, the wave must pass 2 times
    // so the previous delay (delayFromAngle) must be divided by 2
    float delay = delayFromAngle / 2;
    
    float delayedP = (1234 + p - delay)%1;
    float angleChangeProgress = -pow(1-delayedP,2.0); // sudden angle change, and stops moving at the end
    // this formula was found with pen and paper, for it to match the wave speed
    
    // getting the position on sphere
    PVector position = rotY(position0, angleChangeProgress * TAU);
    
    
    // digit size style...
    float wo = (1234 - 4*p + delayFromAngle)%1;
    float wv = pow(c01(sin(PI*wo)),3.3);
    float sizeFactor = 2.8 + 1.3*wv;
    // size bump style stuff when starting to move
    float bumpMax = 0.5;
    float bump = 1 + bumpMax*pow(1-c01(27*delayedP),2.3);
    float bump2 = 1 + bumpMax*pow(1-c01(100*(1-delayedP)),2.0);
    
    float sizeFactor2 = sizeFactor * bump * bump2;
    boolean isDigit = true;
    float alphaFactor = 1.0;
    
    showParticle(position, sizeFactor2, isDigit, digitValue, alphaFactor);
  }
  
  // replacement technique (https://bleuje.com/tutorial4/)
  void show()
  {
    int K = 2;
    for(int i=0;i<K;i++)
    {
      show((i+t)/K);
    }
  }
}

ArrayList<Digit> digitsArray = new ArrayList<Digit>();

void setup()
{
  size(600,600,P2D);
  result = new int[width*height][3];
  smooth(8);
  
  // the font that was used, deactivated here so that it runs without the font file
  //mono = createFont("Manrope-Medium.ttf", 128);
  //textFont(mono);
  
  for(int i=0;i<numberOfDigits;i++)
  {
    digitsArray.add(new Digit(i));
  }
}


void draw_()
{
  background(0);
  push();
  translate(width/2,height/2);
  
  for(Digit digit : digitsArray)
  {
    digit.show();
  }
  
  showDashedCurve();
  
  pop();
}


/* License:
 *
 * Copyright (c) 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
