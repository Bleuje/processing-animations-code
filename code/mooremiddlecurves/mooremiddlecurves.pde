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

// ease in and out, [0,1] -> [0,1], with a parameter g:
// https://patakk.tumblr.com/post/88602945835/heres-a-simple-function-you-can-use-for-easing
float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
}

// defines a map function variant to constrain or not in target interval (exists in openFrameworks)
float map(float x, float a, float b, float c, float d, boolean constr)
{
  return constr ? constrain(map(x,a,b,c,d),min(c,d),max(c,d)) : map(x,a,b,c,d);
}

// short one to map an x from [a,b] to [0,1] and constrain
float mp01(float x, float a, float b)
{
  return map(x,a,b,0,1,true);
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
      t = map(frameCount-1 + sa*shutterAngle/samplesPerFrame, 0, numFrames, 0, 1) + 0.6;
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

int samplesPerFrame = 5;
int numFrames = 335;        
float shutterAngle = 1.3;

boolean recording = false;

int curveSize = 32; // must be a power of 2

int numberOfVertices = curveSize * curveSize;

// Hilbert curve algo from Wikipedia in functions d2xy_hilbert and rot below (https://en.wikipedia.org/wiki/Hilbert_curve)

// convert d (it's an index of a vertex on the curve's path) to (i,j) position
// n * n is the number of vertices, a power of 4 : pow(4,j) where j is the order/level of the curve
PVector d2xy_hilbert(int n, int d) {
    int rx, ry, s, t=d;
    float x,y;
    x = 0;
    y = 0;
    for (s=1; s<n; s*=2) {
        rx = 1 & (t/2);
        ry = 1 & (t ^ rx);
        PVector res = rot(s, new PVector(x,y), rx, ry);
        x = res.x;
        y = res.y;
        x += s * rx;
        y += s * ry;
        t /= 4;
    }
    
    return new PVector(x,y);
}

//rotate/flip a quadrant appropriately
PVector rot(int n, PVector input, int rx, int ry) {
  float x = input.x;
  float y = input.y;
    if (ry == 0) {
        if (rx == 1) {
            x = n-1 - x;
            y = n-1 - y;
        }

        //Swap x and y
        float t  = x;
        x = y;
        y = t;
    }
    return new PVector(x,y);
}

// Moore curve (https://en.wikipedia.org/wiki/Moore_curve)
// convert d to (x,y), using 4 Hilbert curves.
PVector d2xy_moore(int n1, int d) {
    int n = n1/2; // n for 2 times smaller Hilbert curve than this Moore curve
    int m = n*n;
    
    d = (d+4*m)%(4*m); // just making sure d is in [0,4*m[
    
    PVector aux = d2xy_hilbert(n,d%m); // position on local Hilbert curve
    
    if(d<m) return new PVector(aux.x,n-aux.y-1);
    else if(d<2*m) return new PVector(aux.x+n,n-aux.y-1);
    else if(d<3*m) return new PVector(n-aux.x+n-1,aux.y+n);
    else if(d<4*m) return new PVector(n-aux.x-1,aux.y+n);

    return new PVector(0,0); // we should never reach this case
}

PVector [] precomputedMoore = new PVector[numberOfVertices];

void precomputeMoore()
{
  for(int i=0;i<numberOfVertices;i++)
  {
    precomputedMoore[i] = d2xy_moore(curveSize, i);
  }
}

PVector getMooreIntegerPosition(int i)
{
  i = ((i%numberOfVertices)+numberOfVertices)%numberOfVertices; // loop the index
  return precomputedMoore[i];
}

// ix and iy are integer positions of the grid
PVector pixelpos(float ix,float iy)
{
  float margin = 15;
  float W = 600; // = width in 600x600, useful to avoid Processing's width variable, to be able to change easily the resolution with scale function
  float x = map(ix, 0, curveSize-1, margin, W-margin) - W/2;
  float y = map(iy, 0, curveSize-1, margin, W-margin) - W/2;
  return new PVector(x,y);
}

// position on the curve from p in [0, curveSize * curveSize]
// just interpolating between positions of the Moore curve's vertices positions
PVector moorePosition0(float p)
{
  int ind1 = floor(p);
  int ind2 = ind1+1;
  
  PVector ipos1 = getMooreIntegerPosition(ind1);
  PVector ipos2 = getMooreIntegerPosition(ind2);

  PVector v1 = pixelpos(ipos1.x,ipos1.y);
  PVector v2 = pixelpos(ipos2.x,ipos2.y);
  
  PVector res = v1.copy().lerp(v2, p - ind1);
  return res;
}

// position on the curve with q in [0, 1]
PVector moorePosition(float q, float vertexPositionOffset)
{
  float p = q * numberOfVertices; // maps q to vertex index range, to call position0 function
  return moorePosition0(p + vertexPositionOffset);
}

// previous code was just for the Moore curve
/////////////////////////////////////////////

// fuction to play with
float delayFunction(PVector v)
{
  //return atan2(v.y,v.x);
  return (v.x+v.y)*0.004; // diagonal offset
}

// main trick to go towards alternative curves
// see explanation here: https://mastodon.social/@bleuje/111709161970031114
PVector middlePositionTrickCurve(float p)
{
  PVector v1 = moorePosition(p,0);
  
  float offset = delayFunction(v1);
  float sine = pow(ease(mp01(sin(TAU*t-offset),-1,1),2.0),1.4); // activation from Moore to the other curves
  int maximumNextPointOffset = 16; // interesting parameter to tune
  PVector v2 = moorePosition(p,sine * maximumNextPointOffset);
  
  PVector v = v1.copy().add(v2).mult(0.5); // middle between v1 and v2
  return v;
}


void setup()
{
  size(720,720,P3D);
  result = new int[width*height][3];
  smooth(8);
  
  precomputeMoore(); // Moore curve positions can be computed only at setup, this is a little optimization
}


void draw_()
{
  background(0);
  push();
  translate(width/2,height/2);
  
  scale(720.0/600);
  
  int M = 50; // every M small dots that make lines, there is a "big" dot
  int m = numberOfVertices * M; // number of dots that are drawing the curve
  
  for(int i=0;i<m;i++)
  {
    float p = 1.0*i/m;
    PVector v = middlePositionTrickCurve(p);

    float offset = delayFunction(v);
    // stuff to control the switch between "line or dot" styles
    float styleSine1 = ease(mp01(cos(TAU*t-offset-0.4*HALF_PI),-1,1),2.0); // curve style
    float styleSine2 = ease(mp01(cos(TAU*t-offset-0.8*HALF_PI),-1,1),2.0); // (big) dots style
    
    float curveAlpha = 180;
    
    if(i%M==0) // i is on a big dot
    {
      stroke(255,255 - (255 - curveAlpha) * styleSine2);
      strokeWeight(3.5 - 2 * styleSine2);
    }
    else // else we're in between dots, so we will draw a small dot, with lots of them it looks like a connected curve
    {
      stroke(255,curveAlpha * styleSine1);
      strokeWeight(1.0 + 0.5 * styleSine1);
    }
    
    point(v.x,v.y);
  }
  
  pop();
}


/* License:
 *
 * Copyright (c) 2024 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder, except for the code coming from Wikipedia.
 * Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
