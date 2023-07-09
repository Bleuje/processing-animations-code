// Processing code by Etienne Jacob
// motion blur template by beesandbombs
// opensimplexnoise code (by Kurt Spencer) in another tab is necessary
// --> code here : https://gist.github.com/Bleuje/fce86ef35b66c4a2b6a469b27163591e
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/sunconnections/

int[][] result;
float t, c;

void draw() {

  if (!recording) {
    t = mouseX*1.0/width;
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

    saveFrame("fr###.gif");
    println(frameCount,"/",numFrames);
    if (frameCount==numFrames)
      stop();
  }
}

//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 3;
int numFrames = 93;        
float shutterAngle = .6;

boolean recording = false;

OpenSimplexNoise noise;

// note: good parameters have been lost

int n = 75; // number of white dots
int numberOfDotsOnCurve = 100; // connection drawing quality
float noiseLoopRadius = 0.2; // noise circle radius
float globalDelayFactor = 4.2; // delay effect parameter
float swmax = 1.7; // maximum stroke weight
float D = 150; // global displacement intensity factor

class Dot
{
  // polar coordinates
  float r = pow(random(1),0.2)*0.3*width; // radius random distribution to have less dots near the center
  float theta = random(TWO_PI);
  
  // position without displacement
  float x0 = r*cos(theta);
  float y0 = r*sin(theta);
  
  float displacementFactor = map(dist(x0,y0,0,0),0,0.3*width,3.4,0);
  // (more movement for the dots nearer the center)
  
  float seed = random(10,1000);
  
  float x(float p)
  {
    return x0 + displacementFactor*D*(float)noise.eval(seed + noiseLoopRadius*cos(TWO_PI*p),noiseLoopRadius*sin(TWO_PI*p));
  }
  
  float y(float p)
  {
    return y0 + displacementFactor*D*(float)noise.eval(2*seed + noiseLoopRadius*cos(TWO_PI*p),noiseLoopRadius*sin(TWO_PI*p));
  }
  
  void show(float p)
  {
    stroke(255);
    fill(255);
    
    ellipse(x(p),y(p),3,3);
  }
}

Dot[] array = new Dot[n];

void setup()
{
  size(500,500,P3D);
  result = new int[width*height][3];
  
  randomSeed(456);
  
  noise = new OpenSimplexNoise();
  
  for(int i=0;i<n;i++){
    array[i] = new Dot();
  }
  
  smooth(8);
}

void draw_()
{
  background(0);
  
  push();
  translate(width/2,height/2);
  
  // draw white dots
  for(int i=0;i<n;i++)
  {
    array[i].show(t);
  }
  
  // draw connections
  for(int i=0;i<n;i++)
  {
    for(int j=0;j<i;j++)
    {
      float distanceToCenter = dist(array[i].x(t),array[i].y(t),array[j].x(t),array[j].y(t));
      
      float sw = constrain(map(distanceToCenter,0,0.45*width,swmax,0),0,swmax);
      strokeWeight(sw);
      stroke(255,50); // curve drawn with small transparent dots
      
      float delayFactor = distanceToCenter*globalDelayFactor/width; // strength of the delay effect explained later
      
      for(int k=0;k<=numberOfDotsOnCurve;k++)
      {
        float q = map(k,0,numberOfDotsOnCurve,0,1); // parameter in [0,1], indicates where we are on the connection curve
        // (at q=0 we're on dot i, at q=1 we're on dot j)
        
        // main trick here: interpolation between the positions of dots i and j,
        // but seeing them with more delay when further from them
        PVector v1 = new PVector(array[i].x(t-delayFactor*q),array[i].y(t-delayFactor*q)); // when q=0 it gives v1 = (array[i].x(t), array[i].y(t))
        PVector v2 = new PVector(array[j].x(t-delayFactor*(1-q)),array[j].y(t-delayFactor*(1-q))); // when q=1 it gives v2 = (array[j].x(t), array[j].y(t))
        
        PVector interpolatedPosistion = v1.lerp(v2,q);
        
        point(interpolatedPosistion.x,interpolatedPosistion.y);
      }
    }
  }
  
  pop();
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
