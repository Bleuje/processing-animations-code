// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/spiralmagic/

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

// ease in and out, [0,1] -> [0,1], with a parameter g:
// https://patakk.tumblr.com/post/88602945835/heres-a-simple-function-you-can-use-for-easing
float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
}

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

int samplesPerFrame = 7;
int numFrames = 500;        
float shutterAngle = .8;

boolean recording = false;

// IDEA : working with Processing in 2D mode, and self made projection, for projection trick
// what the projection trick is about :
// having fixed z position, desired x y 2D screen position, and finding the correct 3D space position for that

float changeEventTime = 0.42;
float cameraZ = -400;
float cameraTravelDistance = 3400;
float startDotYOffset = 28; // y offset of start dot, I think it looks a bif nicer with that
float viewZoom = 100; // "zoom" constant without effect due to some normalization in the formulas
int numberOfStars = 5000; // number of stars

void showProjectedDot(PVector v,float sizeFactor)
{
  float t2 = constrain(map(t,changeEventTime,1,0,1),0,1);
  float newCameraZ = cameraZ + ease(pow(t2,1.2),1.8)*cameraTravelDistance; // increasing camera z in second half of animation
  if(v.z>newCameraZ)
  {
    float dotDepthFromCamera = v.z-newCameraZ;

    // 3D -> 2D projection formulas :
    float x = viewZoom*v.x/dotDepthFromCamera;
    float y = viewZoom*v.y/dotDepthFromCamera;
    float sw = 400*sizeFactor/dotDepthFromCamera;
    
    strokeWeight(sw);
    point(x,y);
  }
}

// 2D spiral path with easing
PVector spiralPath(float p)
{
  p = constrain(1.2*p,0,1); // for large p we keep the same position at the end of the spiral
  p = ease(p,1.8);
  int numberOfSpiralTurns = 3;
  float theta = TWO_PI*numberOfSpiralTurns*sqrt(p); // sqrt to have smooth spiral curve parametrization
  float r = 170*sqrt(p);
  // x y from previous polar coordinates
  float x = r*cos(theta);
  float y = r*sin(theta);
  y += startDotYOffset;
  return new PVector(x,y);
}

// one particle
class Star
{
  // the random x and y displacements of the star on 2D screen
  float dx = 30*random(-1,1);
  float dy = 30*random(-1,1);
  
  float spiralLocation; // parameter for location on the spiral curve
  float strokeWeightFactor = pow(random(1),2.0); // random strokeWeight factor
  
  float z; // fixed z of the star
  
  Star()
  {
    z = random(0.5*cameraZ,cameraTravelDistance+cameraZ); // random star z between two bounds
    spiralLocation = (1-pow(1-random(1),3.0))/1.3; // location on the spiral curve parameter, with some nice random distribution
    z = lerp(z,cameraTravelDistance/2,0.3*spiralLocation); // changing z so that it's further from camera as the parameter of the spiral increases
  }
  
  void show(float p) // p (in [0,1]) increases with time
  {
    PVector spiralPos = spiralPath(spiralLocation);
    float q = p-spiralLocation;
    if(q>0) // show only if the time is further than spiral location
    {
      float displacementProgress = constrain(5*q,0,1); // progress to go to displaced positions, reaches maximum progress of 1 quickly in function of q
      float easing = 1-pow(1-displacementProgress,4.0); // easing for the travel to displaced postion (start fast then slow down)
      
      float screenX = lerp(spiralPos.x,spiralPos.x+dx,easing);
      float screenY = lerp(spiralPos.y,spiralPos.y+dy,easing);
      // this gave us 2D screen positions we want
      
      // now we want to find position in 3D space, to be at the star's z
      // to do that we invert the projection formulas
      float vx = (z-cameraZ)*screenX/viewZoom;
      float vy = (z-cameraZ)*screenY/viewZoom;
      // this is our 3D position
      PVector u = new PVector(vx,vy,z);
      
      float dotSize = 8.5*strokeWeightFactor;
      showProjectedDot(u,dotSize); // now we can project this 3D position to 2D screen and show it
    }
  }
}

void drawStartDot()
{
  if(t>changeEventTime){
    float dy = cameraZ*startDotYOffset/viewZoom; // some inverted projection again to get y position in 3D space
    PVector v = new PVector(0,dy,cameraTravelDistance); // 3D position
    showProjectedDot(v,2.5);
  }
}

Star [] array = new Star[numberOfStars];

void setup(){
  size(500,500,P2D);
  result = new int[width*height][3];
  
  randomSeed(1234);
  
  for(int i=0;i<numberOfStars;i++)
  {
    array[i] = new Star();
  }
  
  smooth(8);
}

void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  stroke(255);
  
  float t1 = constrain(map(t,0,changeEventTime+0.25,0,1),0,1); // time parameter from 0 to 1 for first half
  float t2 = constrain(map(t,changeEventTime,1,0,1),0,1); // time parameter from 0 to 1 for second half
  
  rotate(-PI*ease(t2,2.7)); // camera rotation during second part
  
  // drawing dot with trail, larger and longer trail at intermediate time (with sin(PI*t1) factor)
  int N = 80; // number of dots to make the trail
  for(int i=0;i<N;i++)
  {
    float f = map(i,0,N,1.1,0.1); // factor for larger dots at the begining of the trail
    float sw = (1.3*(1-t1) + 3.0*sin(PI*t1))*f; // stroke weight evolution formula
    strokeWeight(sw);
    
    PVector v = spiralPath(t1-0.00015*i); // time offset in function of dot index i, that makes the trail
    point(v.x,v.y);
  }
  
  // drawing stars/particles
  for(int i=0;i<numberOfStars;i++)
  {
    array[i].show(t1);
  }
  
  drawStartDot();

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
