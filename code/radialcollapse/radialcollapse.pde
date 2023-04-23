// Processing code by Etienne JACOB
// motion blur template by beesandbombs
// opensimplexnoise code in another tab is be necessary
// --> code here : https://gist.github.com/Bleuje/fce86ef35b66c4a2b6a469b27163591e
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/radialcollapse/

// A lot of hidden blocks are drawn, I don't really care, but it's very slow

int[][] result;
float t, c;

float ease(float p, float g) {
  if (p < 0.5) 
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
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

    saveFrame("fr###.gif");
    println(frameCount,"/",numFrames);
    if (frameCount==numFrames)
      exit();
  }
}

// end of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 4;
int numFrames = 50;        
float shutterAngle = .75;

boolean recording = false;

OpenSimplexNoise noise;

// "fractal zoom" ratio
float RATIO = 0.8;

// sizes for the 3D grid (repeated with replacement technique)
int N = 3; // numbers of blocks on changing radius axis
int m = 70; // number of blocks on changing theta "axis"
int nz = 8; // number of blocks on changing z axis
// nz is reduced a bit compared to rendered version but it's still very slow

float DZ = 21.0; // blocks height parameter

// one block :
class Thing{
  int i,j,l;
  float offset;
  
  Thing(int i_,int j_,int l_)
  {
    i = i_; // "changing radius" index
    j = j_; // "theta" index
    l = l_; // height index
    
    float theta = (j+0.5)*TWO_PI/m;
    float noiseRadius = 2.0;
    
    // offset/delay to control the trigerring of the fall :
    offset = -0.4*(float)noise.eval(2*i,2*j); // small noise based on (x,y) position
    offset -= 2.7*(float)noise.eval(4337+noiseRadius*cos(theta),noiseRadius*sin(theta)); // looping noise that gives the shape of the hole
    offset += 1.0*i/N; // blocks of the grid have more and more delay when they are far from center
    offset -= 0.07*l; // blocks at the bottom fall first
    offset -= 2.7; // constant delay parameter (so it controls the size of the big hole)
  }
  
  float seed = random(10,1000);
  float col = random(230,265); // color parameter
  float sw = random(0.3,0.7); // stroke weight parameter
  
  void show(float p)
  {
    float theta1 = j*TWO_PI/m;
    float theta2 = (j+1)*TWO_PI/m;
    
    float R = 100.0;
    float r1 = pow(RATIO,p)*pow(1/RATIO,1.0*i/N)*R;
    float r2 = pow(RATIO,p)*pow(1/RATIO,1.0*(i+1)/N)*R;
    // the 2 lines above are a bit technical,
    // it's using both fractal zoom factor (pow(RATIO,p)) and adjustment based on i
    // to have radius change smoothly on the grid with i
    
    // x,y positions of the block's vertices
    float x1 = r1*cos(theta1);
    float y1 = r1*sin(theta1);
    float x2 = r1*cos(theta2);
    float y2 = r1*sin(theta2);
    float x3 = r2*cos(theta2);
    float y3 = r2*sin(theta2);
    float x4 = r2*cos(theta1);
    float y4 = r2*sin(theta1);
    
    
    // transforming p with offset. It will start to fall when p>=offset which is the same as pp>=0
    float pp = p - offset;
    float q = max(0,0.5*pp); // no fall while q=0
    
    float zFall = pow(RATIO,p)*1700*pow(q,2.0); // fall length
    float blockHeight = DZ*pow(RATIO,p); // block height, changing with fractal zoom factor
    float z = -zFall-l*blockHeight; // fall + height change because of height index
    
    push();
    translate(0,0,z);
    
    // changing stroke weight with p and noise
    float f = 0.5+5*pow(map((float)noise.eval(seed+1.0*p,0),-1,1,0,1),3.0);
    strokeWeight(sw*f);
    stroke(col+0.34*z);
    fill(0);
    
    beginShape();
    vertex(x1,y1,0);
    vertex(x2,y2,0);
    vertex(x3,y3,0);
    vertex(x4,y4,0);
    endShape(CLOSE);
    beginShape();
    vertex(x1,y1,0);
    vertex(x2,y2,0);
    vertex(x2,y2,-blockHeight);
    vertex(x1,y1,-blockHeight);
    endShape(CLOSE);
    beginShape();
    vertex(x3,y3,0);
    vertex(x4,y4,0);
    vertex(x4,y4,-blockHeight);
    vertex(x3,y3,-blockHeight);
    endShape(CLOSE);
    beginShape();
    vertex(x1,y1,0);
    vertex(x4,y4,0);
    vertex(x4,y4,-blockHeight);
    vertex(x1,y1,-blockHeight);
    endShape(CLOSE);
    beginShape();
    vertex(x2,y2,0);
    vertex(x3,y3,0);
    vertex(x3,y3,-blockHeight);
    vertex(x2,y2,-blockHeight);
    endShape(CLOSE);
    beginShape();
    vertex(x1,y1,-blockHeight);
    vertex(x2,y2,-blockHeight);
    vertex(x3,y3,-blockHeight);
    vertex(x4,y4,-blockHeight);
    endShape(CLOSE);
    pop();
  }
  
  // replacement technique :
  int K = 5;
  void show()
  {
    for(int ii=-2*K;ii<K;ii++)
    {
      show(ii+t);
    }
  }
}

// array of all blocks :
Thing[] array = new Thing[m*N*nz];

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  
  noise = new OpenSimplexNoise();
  
  int k=0;
  for(int i=0;i<N;i++){
    for(int j=0;j<m;j++){
      for(int l=0;l<nz;l++){
        array[k] = new Thing(i,j,l);
        k++;
      }
    }
  }
  
  smooth(8);
}

void draw_(){
  background(0);
  push();
  
  translate(width/2,height/2);
  
  rotateX(0.8);
  translate(0,0,100);
  
  for(int i=0;i<N*m*nz;i++)
  {
    array[i].show();
  }
  
  pop();
}


/* License:
 *
 * Copyright (c) 2020, 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
