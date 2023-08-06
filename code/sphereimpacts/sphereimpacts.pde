// Processing code by Etienne JACOB
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/sphereimpacts/

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

int samplesPerFrame = 8;
int numFrames = 150;        
float shutterAngle = 1.0;

boolean recording = false;

float blackSphereRadius = 110;

class BigParticle
{
   // angles for coordinates rotations, controls where the impact falls
   // random distributions making uniform distribution
  float theta = random(TWO_PI);
  float phi = acos(2*random(1)-1);
  
  float offset = random(1); // makes different particles start at different times
  float sz = 2+3.5*pow(random(1),2.0); // particle size factor
  float seed = random(100,10000);
  int nuberOfExplosionParticles = floor(random(8,12))*2;
  
  float elpasedTimeBeforeImpact = 0.5;
  
  // show before impact
  void beforeImpactShow(float p) // p is the progress in [0,1]
  {
    float r = map(p,0,1,7*blackSphereRadius,blackSphereRadius);
    push();
    // coordinates rotations
    rotateZ(theta);
    rotateX(phi);
    
    push();
    translate(0,0,r); // because we rotated coordinates well, we can just move on z axis now
    
    float ellipseSize = 0.85*sz*p*sin(PI*p)+1.5; // larger ellpise size at mid-flight
    
    strokeWeight(sz*p);
    stroke(255);
    noStroke();
    fill(255);
    
    ellipse(0,0,ellipseSize,ellipseSize);
    
    pop();
    pop();
  }
  
  // show explosion
  void afterImpactShow(float p) // p is the progress in [0,1]
  {
    push();
    // coordinates rotation, after that, the big particle just comes from changing z
    rotateZ(theta);
    rotateX(phi);
    
    randomSeed(floor(seed));
    
    for(int i=0;i<nuberOfExplosionParticles;i++)
    {      
      // controlling where the small particle will move to
      float xTravelLength = 4*random(25,50)/2;
      float theta2 = random(TWO_PI);
      float zTravelLength = random(0,xTravelLength/2);
      
      push();
      // we rotate locally around the z-axis
      rotateZ(theta2);
      
      push();
      float xPos = p*xTravelLength;
      float yPos = 0; // no y change is used because we rotated with a random angle around z-axis, so we can just move on x-axis
      float zPos = blackSphereRadius+p*zTravelLength;
      translate(xPos,yPos,zPos);
      
      float smallEllipseSize = random(4)*(1-p);
      
      stroke(255);
      noStroke();
      fill(255);
      
      ellipse(0,0,smallEllipseSize,smallEllipseSize);
      
      pop();
      pop();
    }
    pop();
  }
  
  void show(float p) // p is the progress parameter, in [0,1]
  {
    if(p<=elpasedTimeBeforeImpact)
    {
      int m = 50; // drawing m times with delay for trail drawing
      float q = map(p,0,elpasedTimeBeforeImpact,0,1);
      float trailDelayWidth = (1-q)*0.1*sin(PI*q); // longer trail at mid flight
      for(int i=0;i<m;i++)
      {
        beforeImpactShow(q-trailDelayWidth*i/m);
      }
    }
    else
    {
      float q = map(p,elpasedTimeBeforeImpact,1,0,1);
      afterImpactShow(q);
    }
  }
  
  void show()
  {
    float p = (t+offset)%1; // random offset so that big particles don't start at the same time
    show(p);
  }
  
}

int n = 600;

BigParticle [] array = new BigParticle[n];

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  
  for(int i=0;i<n;i++)
  {
    array[i] = new BigParticle();
  }
}

void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  // drawing big black sphere
  stroke(255);
  fill(0);
  noStroke();
  sphereDetail(30);
  sphere(blackSphereRadius);
  
  // drawing all the particles stuff
  for(int i=0;i<n;i++)
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
