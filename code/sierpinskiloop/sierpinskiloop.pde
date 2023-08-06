// Processing code by Etienne JACOB
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://twitter.com/etiennejcb/status/1367173073250758661

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

int samplesPerFrame = 5;
int numFrames = 180;        
float shutterAngle = .6;

boolean recording = false;

int DEPTH = 5; // recursion depth
float SWMAX = 3.0; // stroke weight max
float R = 300; // size of drawing

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
}

// v1,v2,v3 are the vertices of a current triangle to draw, this function is recursive
// it is the current index of iterations
// p is a time parameter
void drawFractal(float p,PVector v1,PVector v2,PVector v3,int iterationsIndex)
{
  if(iterationsIndex>=DEPTH) return;
  
  float sw = map(iterationsIndex+p,0,DEPTH,SWMAX,0);
  strokeWeight(sw);
  
  triangle(v1.x,v1.y,v2.x,v2.y,v3.x,v3.y);
  
  // now let's draw the triangles inside...
  
  PVector u1 = v1.copy().add(v2).mult(0.5); // position at the middle between v1 and v2
  PVector u2 = v2.copy().add(v3).mult(0.5); // position at the middle between v2 and v3
  PVector u3 = v3.copy().add(v1).mult(0.5); // position at the middle between v3 and v1
  
  drawFractal(p,v1,u1,u3,iterationsIndex+1);
  drawFractal(p,u1,v2,u2,iterationsIndex+1);
  drawFractal(p,u3,u2,v3,iterationsIndex+1);
}

// first level with some new fractal triangles coming in
void drawThing(float p,PVector v1,PVector v2,PVector v3)
{
  PVector u1 = v1.copy().add(v2).mult(0.5); // position at the middle between v1 and v2
  PVector u2 = v2.copy().add(v3).mult(0.5); // position at the middle between v2 and v3
  PVector u3 = v3.copy().add(v1).mult(0.5); // position at the middle between v3 and v1
  
  PVector w1 = v2.copy().lerp(u1,p); // go from v2 to u1 with time
  PVector w2 = v2.copy().lerp(u2,p); // go from v2 to u2 with time
  PVector w3 = v3.copy().lerp(u2,p); // go from v3 to u2 with time
  PVector w4 = v3.copy().lerp(u3,p); // go from v3 to u3 with time
  
  drawFractal(p,v1,w1,w4,0);
  drawFractal(p,w1,v2,w2,0);
  drawFractal(p,w4,w3,v3,0);
}

void draw_(){
  background(0);
  push();
  translate(width/2,height/2+50);
  
  // defining the main triangle vertices' positions
  float a1 = TWO_PI*0.0/3.0-HALF_PI;
  PVector v1 = new PVector(R*cos(a1),R*sin(a1));
  float a2 = TWO_PI*1.0/3.0-HALF_PI;
  PVector v2 = new PVector(R*cos(a2),R*sin(a2));
  float a3 = TWO_PI*2.0/3.0-HALF_PI;
  PVector v3 = new PVector(R*cos(a3),R*sin(a3));
  
  noFill();
  
  blendMode(ADD); // to add layers of red, green and blue drawings, for chromatic aberration style
  
  for(int col=0;col<3;col++) // RGB chromatic aberration loop
  {
    stroke(255*int(col==0),255*int(col==1),255*int(col==2)); // draw in red, green or blue depending on col
    
    strokeWeight(SWMAX);
    triangle(v1.x,v1.y,v2.x,v2.y,v3.x,v3.y); // drawing the main triangle
    
    int N = 16;
    for(int i=0;i<N;i++){ // drawing the fractal N times, changing the time with little delays (trail effect)
      float t2 = 3*t + 0.011*col + 0.0015*i; // delay both based on R, G or B color, and on i of the loop*
      
      float rotationIndex = floor(t2)%3; // we draw the scene with 3 different successive rotations
      float q = t2%1; // fractional part for time inside current rotation
      
      push();
      rotate(TWO_PI*rotationIndex/3);
      drawThing(ease(constrain(q,0,1),2.1),v1,v2,v3);
      pop();
    }
  }
  
  blendMode(NORMAL);


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
