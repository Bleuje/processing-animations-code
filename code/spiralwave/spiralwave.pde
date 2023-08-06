// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/spiralwave/

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

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
      saveFrame("fr###.gif");
      println(frameCount,"/",numFrames);
    }
    
    if (frameCount==numFrames)
      stop();
  }
}

// End of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 5;
int numFrames = 75;        
float shutterAngle = 1.2;

boolean recording = false;

int numberOfParticles = 17000;


// 3D spiral surface equation, changing with t
// [0,1]x[0,1] 2D input paraemters to 3D position function, the spiral's center is at parameters (0.5,0.5)
PVector surface(float px,float py)
{
  // converting px,py to (x,y) pixel positions
  float x = map(px,0,1,-600,600)*1.75;
  float y = map(py,0,1,-600,600)*1.75;
    
  // now let's find z  
  // distance from center + angle from center gives a spiral delay/offset
  float delay = dist(px-0.5,py-0.5,0,0)*8 + atan2(py-0.5,px-0.5)/TWO_PI;
  
   // wave intensity increasing with distance, pow for function shaping (increases less and less)
  float waveIntensity = pow(dist(px-0.5,py-0.5,0,0),0.5)*50.0;
  
  // mapping a sine wave using the spiral delay to [-6,2] sinusoidal wave
  float z = waveIntensity*map(sin(TWO_PI*(t-delay)),-1,1,-6,2);
  
  return new PVector(x,y,z);
}

int meshSize = 130; // mesh quality parameter

// draw black surface mesh
void drawBlackSurface()
{
  for(int i=0;i<meshSize;i++)
  {
    fill(0);
    stroke(255,23);
    strokeWeight(1.2);
    noStroke();
    for(int j=0;j<meshSize;j++)
    {
      // drawing 2 black triangles at (i,j) using the positions on surface
      float px1 = 1.0*i/meshSize;
      float px2 = 1.0*(i+1)/meshSize;
      float py1 = 1.0*j/meshSize;
      float py2 = 1.0*(j+1)/meshSize;
      
      PVector v1 = surface(px1,py1);
      PVector v2 = surface(px2,py1);
      PVector v3 = surface(px2,py2);
      PVector v4 = surface(px1,py2);
      
      beginShape();
      vertex(v1.x,v1.y,v1.z);
      vertex(v2.x,v2.y,v2.z);
      vertex(v3.x,v3.y,v3.z);
      endShape();
      
      beginShape();
      vertex(v1.x,v1.y,v1.z);
      vertex(v4.x,v4.y,v4.z);
      vertex(v3.x,v3.y,v3.z);
      endShape();
    }
  }
}

// particle moving on the surface, with replacement technique, moves slower than the wave
class Particle
{
  // start position in polar coordinates
  float theta = random(TWO_PI); // angle
  float r0 = pow(random(1),1.4)*0.35; // start radius
  
  float radiusTravelLength = 0.5; // in input surface parameters space
  float offset = random(1); // offset so that particles don't start all at the same time
  float sz = pow(random(1),2.0)*6.0; // size factor, for variety
  
  PVector positionOn3DSurface(float p)
  {
    float r = r0 + p*radiusTravelLength;
    
    float px = 0.5+r*cos(theta);
    float py = 0.5+r*sin(theta);
    PVector v = surface(px,py);
    
    return new PVector(v.x,v.y,v.z+2.5); // + 2.5 to be a bit higher than the black surface
  }
  
  void show(float p)
  {
    PVector pos = positionOn3DSurface(p);
    
    push();
    translate(pos.x,pos.y,pos.z);
    
    // point size adjustments
    float s = sz*pow(sin(PI*p),0.5); // sin(PI*x) is 0 for x=0 and x=1, and 1 in the middle, used to fade size at start and end
    // now using depth from camera, for smaller dots in the distance (point(x,y) function does not do this naturally as opposed to sphere(r) function)
    float depth = modelZ(0,0,0);
    float sw = 500.0*s/(max(25,630-depth));
    
    strokeWeight(sw);
    stroke(255);
    
    point(0,0);
    pop();
  }
  
  // replacement technique
  float K = 6;
  void show()
  {
    float tt = (t+offset)%1;
    for(int i=0;i<K;i++)
    {
      float p = 1.0*(i+tt)/K;
      show(p);
    }
  }
}

Particle [] array = new Particle[numberOfParticles];

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  
  randomSeed(1234);
  
  for(int i=0;i<numberOfParticles;i++)
  {
    array[i] = new Particle();
  }
}

void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  translate(0,-90);
  rotateX(0.58*HALF_PI);
  rotate(0.5*HALF_PI);
  
  drawBlackSurface();
  
  for(int i=0;i<numberOfParticles;i++)
  {
    array[i].show();
  }

  pop();
}


/* License:
 *
 * Copyright (c) 2021, 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
