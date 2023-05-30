// Processing code by Etienne JACOB
// motion blur template by beesandbombs
// needs opensimplexnoise code in another tab
// --> code here : https://gist.github.com/Bleuje/fce86ef35b66c4a2b6a469b27163591e
// See the license information at the end of this file.

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

// end of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 1; // no motion blur if equal to 1
int numFrames = 46;        
float shutterAngle = .6;

boolean recording = false;

OpenSimplexNoise noise;

// note: note a really good animation/code example,
// I should look for other ones for quite simple animation code

int n = 4; // number "changing digit instances"
int K = 2350; // number of digits on a path with replacement technique
int numberOfTurns = 40; // number of spiral turns

class Digit // represents a single element moving with replacement technique, actually with changing displayed digits
{
  float noiseSeed = random(10,1000);
  int seed2 = floor(random(0,10));
  
  void show(float p) // p is in [0,1]
  {
    //////////////////////////////////////////////////
    // This part is a bit experimental and not great,
    // just changing the displayed digit in function of p (and putting the result in the variable named "digit")
    // Not taking the complexity of this into account for the animation difficulty rating.
    // 
    // First: floor on an increasing curve in function of p (curve distorted by noise (the experimental part))
    int curveInteger = floor(600*(p+(float)noise.eval(0.8*p,noiseSeed)));
    //
    // Then, offset the curve with a seed of the Digit instance
    curveInteger += seed2;
    //
    // Then, using a formula to get an integer in [0,9] from curveInteger
    int digit = (curveInteger*7 + 123456) % 10; // modulo 10 to have an integer in [0,9]
    // *7 modulo 10 maps the integers in [0,9] to other integers in [0,9].
    // Using also other numbers than 7 for different Digit instances would be better
    // +123456 to be sure to avoid negative modulo
    //
    // I wanted to have a simple animation example with this one,
    // but it does not seem ideal because of this part
    //////////////////////////////////////////////////
    
    float alpha = 255*constrain(450*p-0.5,0,1); // alpha fade from small p
    // (stays a bit at 0 for very small p)
    
    textSize(14);
    fill(255,alpha);
    
    text(digit,0,0);
  }
}

Digit[] array = new Digit[n];

void setup()
{
  size(600,600,P3D);
  result = new int[width*height][3];
  
  noise = new OpenSimplexNoise();
  
  for(int i=0;i<n;i++)
  {
    array[i] = new Digit();
  }
}

void draw_()
{
  background(0);
  push();
  translate(width/2,height/2);
  rotate(-HALF_PI);
  
  for(int i=0;i<n;i++)
  {
    for(int k=0;k<K;k++)
    {
      float q = k+t; // replacement technique
      q += 1.0*i/n; // added offset in function of digit index
      float p = q/K; // normalization so that p is in [0,1]
      
      float theta = numberOfTurns*TWO_PI*sqrt(p); // sqrt(p) gives constant "speed" on spiral
      float r = 1.0*width*sqrt(p); // max radius is large enough
      // x y from previous polar coordinates
      float x = r*cos(theta);
      float y = r*sin(theta);
      
      push();
      translate(x,y);
      rotate(theta+HALF_PI);
      
      array[i].show(p);
      
      pop();
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
