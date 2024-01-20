// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/moorecurvequeue/

int[][] result;
float t, c;

//////////////////////////////////////////////////////////////////////////////
// Start of template

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

int samplesPerFrame = 6;
int numFrames = 300;        
float shutterAngle = 1.7;

boolean recording = false;

int curveSize = 32; // must be a power of 2

int numberOfStopPositions = curveSize*curveSize/4;

// Hilbert curve algo from Wikipedia in functions d2xy_0 and rot below (https://en.wikipedia.org/wiki/Hilbert_curve)
// I haven't tried to understand it yet, but it's fast and quite easy to use

// convert d (it's an index of a vertex on the curve's path) to (i,j) position
// n * n is the number of vertices, a power of 4 : pow(4,j) where j is the order/level of the curve
PVector d2xy_0(int n, int d) {
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

// convert d to (x,y), Moore curve, using 4 Hilbert curves. (https://en.wikipedia.org/wiki/Moore_curve)
PVector d2xy(int n1, int d) {
    int n = n1/2; // n for 2 times smaller Hilbert curve than this Moore curve
    int m = n*n;
    
    d = (d+4*m)%(4*m); // just making sure d is in [0,4*m[
    
    PVector aux = d2xy_0(n,d%m); // position on local Hilbert curve
    
    if(d<m) return new PVector(aux.x,n-aux.y-1);
    else if(d<2*m) return new PVector(aux.x+n,n-aux.y-1);
    else if(d<3*m) return new PVector(n-aux.x+n-1,aux.y+n);
    else if(d<4*m) return new PVector(n-aux.x-1,aux.y+n);

    return new PVector(0,0); // we should never reach this case
}

// ix and iy are integer positions of the grid
PVector pixelpos(float ix,float iy)
{
  float margin = 110; // (invisible margin due to scale use in draw_)
  float W = 600; // = width in 600x600, useful to avoid Processing's width variable, to be able to change easily the resolution with scale function
  float x = map(ix, 0, curveSize-1, margin, W-margin) - W/2;
  float y = map(iy, 0, curveSize-1, margin, W-margin) - W/2;
  return new PVector(x,y);
}

// position on the curve from p in [0, curveSize * curveSize]
// just interpolating between positions of the Moore curve's vertices positions
PVector position0(float p)
{
  int ind1 = floor(p);
  int ind2 = ind1+1;
  
  PVector ipos1 = d2xy(curveSize, ind1);
  PVector ipos2 = d2xy(curveSize, ind2);

  PVector v1 = pixelpos(ipos1.x,ipos1.y);
  PVector v2 = pixelpos(ipos2.x,ipos2.y);
  
  PVector res = v1.copy().lerp(v2, p - ind1);
  return res;
}

// position on the curve with q in [0, 1]
PVector position(float q, float vertexPositionOffset)
{
  float p = map(q, 0, 1, 0, curveSize * curveSize); // maps q to vertex index range, to call position0 function
  return position0(p + vertexPositionOffset);
}

// easing function taken from https://easings.net/#easeOutElastic
float easeOutElastic(float x)
{
  float c4 = (2*PI)/3;
  if(x<=0) return 0;
  if(x>=1) return 1;
  return pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
}

void showDot(float p0, float vertexPositionOffset)
{
  float p = p0 * numberOfStopPositions; // map p0 input from [0,1] to stop position index range
  float frc = (p+1234)%1; // fractional part indicating progress between 2 stop positions
  
  float moveProgression = constrain(3.8*frc, 0, 1); // speedup + constrain for blocked movement, makes the dots stop
  
  float q = (floor(p) + moveProgression)/numberOfStopPositions; // q in [0,1] indicates position on the curve
  PVector pos = position(q, vertexPositionOffset);
  
  // dot drawing parameters
  float sz = 10;
  float intensity = pow(sin(PI*moveProgression), 5.0);
  intensity = easeOutElastic(intensity);
  
  push();
  translate(pos.x,pos.y);
  stroke(255);
  strokeWeight(1.0);
  fill(0);
  ellipse(0, 0, sz - 5*intensity, sz - 5*intensity);
  
  if(vertexPositionOffset == 0) // if first type of dot, show white dot in circle
  {
    strokeWeight(2.0+(sz-5)*intensity);
    point(0,0);
  }
  pop();
}

// replacement technique (https://bleuje.com/tutorial4/)
void showDotsReplacement()
{
  int K = numberOfStopPositions - 7; // number of drawn dots, implies there will be 7 moving areas of changes :)
  
  for(int i=0;i<K;i++)
  {
    // first type of dot
    float p = (i+t)/K;
    showDot(p,0);
    
    // other type of dot
    float timeOffset = 4.0/numberOfStopPositions;
    float vertexPositionOffset = 2.0;
    p = ((i + t + timeOffset) / K) % 1;
    showDot(p, vertexPositionOffset);
  }
}

void setup()
{
  size(600,600,P3D);
  result = new int[width*height][3];
  smooth(8);
}


void draw_()
{
  background(0);
  push();
  translate(width/2,height/2);

  scale(1.5);
  
  // draw curve...
  translate(0,0,-1); // for curve behind dots
  stroke(180);
  strokeWeight(0.8);
  noFill();
  
  beginShape();
  for(int i=0;i<curveSize*curveSize;i++)
  {
    PVector ipos = d2xy(curveSize, i);
    PVector pos = pixelpos(ipos.x,ipos.y);
    vertex(pos.x,pos.y);
  }
  endShape(CLOSE);
  
  translate(0,0,1);
  
  
  // draw moving dots
  showDotsReplacement();

  pop();
}


/* License:
 *
 * Copyright (c) 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder, except for the code coming from Wikipedia.
 * Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
