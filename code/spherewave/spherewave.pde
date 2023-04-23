// Processing code by Etienne JACOB
// motion blur template by beesandbombs
// opensimplexnoise code (by Kurt Spencer) in another tab is necessary
// --> code here : https://gist.github.com/Bleuje/fce86ef35b66c4a2b6a469b27163591e
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/spherewave/

int[][] result;
float t, c;

float c01(float x)
{
  return constrain(x,0,1);
}

float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
}

float map(float x, float a, float b, float c, float d, boolean constr)
{
  return constr ? constrain(map(x,a,b,c,d),c,d) : map(x,a,b,c,d);
}

// WARNING : little function used a lot here, maps the range [a,b] to [0,1] and constrains in [0,1]
float mp01(float x, float a, float b)
{
  return map(x,a,b,0,1,true);
}

float pow_(float p,float g)
{
  return 1-pow(1-p,g);
}

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

int samplesPerFrame = 7;
int numFrames = 450;        
float shutterAngle = 1.3;

boolean recording = false;

OpenSimplexNoise noise;

int n = 5000; // number of particles

float blackSphereRadius = 140; // black sphere radius
float DR = 48; // additional radius (during mid-time)

// go from v1 to v2 with rotation arround their middle
PVector rotater(PVector v1,PVector v2,float p,PVector orientation)
{
  PVector middle = v1.copy().add(v2).mult(0.5);
  PVector middleToV1 = v1.copy().sub(middle);
  float r = middleToV1.mag();
  
  // orientation vector is orthogonal to a plane on which we move
  PVector basisVector1 = middleToV1.copy().normalize();
  PVector basisVector2 = (orientation.cross(middleToV1)).normalize();
  
  // coordinates of vector in new basis
  float X = r*cos(PI*p);
  float Y = r*sin(PI*p);
  
  PVector v = basisVector1.copy().mult(X).add(basisVector2.copy().mult(Y)); // v = X*basisVector1 + Y*basisVector2
  
  PVector finalPosition = middle.copy().add(v);
  return finalPosition;
}

// vector field defining orientation of previous rotation with "rotater" function
// (a bit abstract)
PVector orienterField(PVector pos) // actually I finally chose that it's a constant field that does not depend on position
{
  float vx = 1;
  float vy = 1;
  float vz = 0.5;
  
  PVector res = new PVector(vx,vy,vz);
  res.normalize();
  return res;
}

// to avoid particles going inside the black sphere
PVector bounder(PVector v)
{
  PVector u = v.copy().normalize();
  u.mult(max(v.mag(),blackSphereRadius));
  return u;
}

// easing function taken from https://easings.net/#easeOutElastic, slightly modified
float easeOutElastic(float x)
{
  float c4 = (2*PI)/3;
  if(x<=0) return 0;
  if(x>=1) return 1;
  return pow(2, -7 * x) * sin((x * 10 - 0.75) * c4) + 1;
}

class Particle
{
  PVector pos1,pos2;
  float delay1;
  PVector orientation;
  float seed = random(10,1000);
  
  Particle(int i)
  {
    // setting (x,y,z) position on black sphere (position at start and end)
    // using special formulas to get evenly distributed positions
    float phi = PI * (3. - sqrt(5.));
    float theta = phi*i;
    float y = map(i,0,n-1,1,-1);
    float radius = sqrt(1 - y * y);
    y *= blackSphereRadius;
    float x = cos(theta) * blackSphereRadius * radius;
    float z = sin(theta) * blackSphereRadius * radius;
    
    pos1 = new PVector(x,y,z);
    
    // orientation of rotation effect
    orientation = orienterField(pos1);
    
    float radius2 = blackSphereRadius+DR*pow(random(0.75)+0.25,1.4);
    pos2 = pos1.copy().normalize().mult(radius2); // position when particle left the black sphere
    // but so far without random displacement
    
    float pw = 2.0;
    float rd = random(1);
    float rd1 = mp01(rd,0,0.5);
    float rd2 = mp01(rd,0.5,1);
    float delay0 = 0.5*pow_(rd1,pw)+0.5*pow(rd2,pw);
    // delay for particles returning on the sphere with this offset, the above code defines a desired random distribution
    delay1 = delay0*0.45;
  }
  
  float sphereSize(float p)
  {
    float noiseRadius = 6.0;
    float ns = map((float)noise.eval(seed+noiseRadius*cos(TWO_PI*p),noiseRadius*sin(TWO_PI*p)),-1,1,0,1);
    return pow(ns,3.0)*2+0.5;
  }
  
  // noisy displacement
  PVector displacement(float p)
  {
    float noiseRadius = 1.4;
    float amplitude = 8;
    float noiseSpaceX = noiseRadius*cos(TWO_PI*p);
    float noiseSpaceY = noiseRadius*sin(TWO_PI*p);
    float dx = amplitude*(float)noise.eval(2*seed+noiseSpaceX,noiseSpaceY);
    float dy = amplitude*(float)noise.eval(3*seed+noiseSpaceX,noiseSpaceY);
    float dz = amplitude*(float)noise.eval(4*seed+noiseSpaceX,noiseSpaceY);
    // (looping noise but not a necessary property because the displacement is 0 at the begining)
    return new PVector(dx,dy,dz);
  }
  
  void show(float p) // p will just be the time t in [0,1]
  {
    p = (12345+p)%1;
    
    // IMPORTANT : time is reversed because I experimented and tried reversed time at some point (sorry about this)
    // after this line of code the progress with p is actually to go from sphere surface to displaced position and then doing the elastic easing to come back to the sphere's surface
    p = 1-p; // maybe try without this line of code to understand it better
    
    // q is how much the particle left the black sphere
    float q = mp01(p-delay1,0,0.25);
    q = ease(q,3.0);
    
    // go from position on sphere to displaced position (when time is not reversed)
    PVector pos = pos1.copy().lerp(pos2.copy().add(displacement(p)),q);
    
    // diagonal delay for main effect
    float delay2 = 0.3 - map(0.5*pos.y-0.5*pos.x,-150,150,0,0.3);
    
    float q2 = mp01(p-delay2,0.3,0.7);
    q2 = 1-easeOutElastic(pow(1-q2,2.0));
    
    // use rotater function and orientation to go back to position on sphere (when time is not reversed)
    PVector v = rotater(pos,pos1,q2,orientation);
    
    float sz = lerp(1.0,sphereSize(p),0.2+0.8*pow(c01(sin(PI*p)),1.5)); // controlling particle size through time
    
    v = bounder(v); // keep position outside of black sphere
    
    push();
    translate(v.x,v.y,v.z);
    
    sphereDetail(5);
    fill(255);
    noStroke();
    
    sphere(sz*0.82);
    
    pop();
  }
  
}

Particle [] particlesArray = new Particle[n];

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  
  noise = new OpenSimplexNoise(1234);
  
  for(int i=0;i<n;i++)
  {
    particlesArray[i] = new Particle(i);
  }
}


void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  sphereDetail(50);
  fill(0);
  noStroke();
  sphere(blackSphereRadius);

  for(int i=0;i<n;i++)
  {
    particlesArray[i].show(t);
  }

  pop();
}


/* License:
 *
 * Copyright (c) 2022, 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
