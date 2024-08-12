// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.

// unfolded cubes tiling inspired by Yann Le Gall:
// https://x.com/Yann_LeGall/status/1813347547454575100
// https://www.instagram.com/p/C9kmvo-PaPh/

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

//-----------------------------------
// some generally useful functions...

float c01(float x)
{
  return constrain(x,0,1);
}

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

int samplesPerFrame = 5;
int numFrames = 285;        
float shutterAngle = 1.6;

boolean recording = false;

int DRAWING_STYLE = 1; // 1 is for truchet style, 0 for digits style

float L = 44; // faces size
int nGridSize = 13; // for floor faces grid, needs to be large enough to fill the canvas
int nCubesGrid = 8; // needs to be large enough to fill the canvas
int numberOfTruchetCurves = 3;
float easingIntensity = 2.0;

float truchetActivation; // global varaible for minor glitch fix


// for truchet pattern drawing, function for drawing one arc
void drawArc(int curveIndex)
{
  if(curveIndex == (numberOfTruchetCurves-1)/2) drawDashedArc(); // middle arc will be dashed
  else // else use plain arc function of Processing
  {
    float r = 2*map(curveIndex,0,numberOfTruchetCurves-1,0.4*L,0.6*L);
    arc(-L/2,-L/2,r,r,0,HALF_PI);
  }
}

// (only used for truchet version)
void drawDashedArc()
{
  float r = L;
  int m = 3; // choice of m dashes for the dashed arcs
  for(int i=0;i<m;i++)
  {
    float theta = map(i+0.5,0,m,0,HALF_PI); // center angle of the dash
    float theta1 = theta - 0.25*HALF_PI/m; // a bit less than theta
    float theta2 = theta + 0.25*HALF_PI/m; // a bit more than theta
    arc(-L/2,-L/2,r,r,theta1,theta2); // tiny arc
  }
}

// rect/square drawing, with dashed contour and small spheres at corners
void drawSquareWithCustomContour()
{
  // plain black square/face
  rectMode(CENTER);
  fill(0);
  noStroke();
  rect(0,0,L,L);
  
  // contour drawing...
  // for code factorization, draw the same things with some rotZ increase of HALF_PI at each iteration
  for(int k=0;k<4;k++)
  {
    push();
    rotateZ(HALF_PI*k);
    stroke(255);
    strokeWeight(1);
    float f = 0.22;
    line(-L/2, -L/2, -L/2, -L/2 + f*L); // corner line 1
    line(-L/2, -L/2, -L/2 + f*L, -L/2); // corner line 2
    line(-L/2, -f*L/2, -L/2, f*L/2); // line at middle of edge
    
    noStroke();
    fill(255);
    sphereDetail(3); // low detail for performance because spheres are small
    push();
    translate(-L/2,-L/2);
    sphere(3); // corner sphere
    pop();
    pop();
  }
}

void drawFace()
{
  drawSquareWithCustomContour(); // drawing the black face with nice contour
  
  // then we must draw on one side of the face
  push();
  translate(0,0,1.8); // little bump to make sure drawing appears only one one side of the face
  
  int faceRotationChoice = floor(random(2)); // always the same choice for this face thanks to seeding at a right time for cube drawing (and same face drawing order)
  rotateZ(faceRotationChoice*HALF_PI);
  
  if(DRAWING_STYLE == 0) // draw digit
  {
    translate(-0.19*L, 0.22*L, 1); // adjustment to position digit at the center of the face
    fill(255);
    noStroke();
    textSize(27);
    
    int digitChoice = floor(random(10)); // always the same for this face thanks to seeding at a right time for cube drawing
    text(digitChoice,0,0);
  }
  else if(DRAWING_STYLE == 1) // draw truchet tile
  {
    for(int i=0;i<numberOfTruchetCurves;i++)
    {
      float progress = map(i,0,numberOfTruchetCurves-1,0,1);
      float sw = 1.5 + 1.0*(1-sin(PI*progress)); // thinner stroke weight in the middle
      strokeWeight(0.5*sw*truchetActivation);
      stroke(255);
      noFill();
      
      
      // this truchet pattern needs to do the curve drawing two times, with PI rotation between the 2 drawings
      push();
      drawArc(i);
      rotate(PI);
      drawArc(i);
      pop();
    }
  }
  
  pop();
}

// function for code factorization, transformations done for the unfolding of a face
void faceUnfoldTransform(float p)
{
  translate(L/2,0,0);
  float theta = HALF_PI + HALF_PI*p;
  rotateY(theta);
  translate(-L/2,0,0);
  rotateX(PI); // (flip that makes the face drawing on the side which is inside the cube)
}

void unfoldAndDrawFace(float p)
{
  faceUnfoldTransform(p);
  drawFace();
}

class Cube
{
  int i,j;
  float digitSeed = random(10000); // seed for randomness of faces drawing
  
  Cube(int i_,int j_)
  {
    i = i_;
    j = j_;
  }
  
  void showUnfold(float progress)
  {
    // Technique : set a seed each time you draw the faces of the cube
    // then use random to get the random choices of the cube which will be always the same thanks to this seeding
    // it's hacky... it's also possible and cleaner to store the list of random choices at the Cube construction
    randomSeed(floor(digitSeed));
    
    float p = ease(progress,easingIntensity); // ease movement
    
    push();
    drawFace(); // draw the face that doesn't move (floor face)
    pop();
    
    push();
    unfoldAndDrawFace(p); // we will do that for the 4 directions (with rotateZ to turn)
    pop();
    
    push();
    rotateZ(HALF_PI);
    unfoldAndDrawFace(p);
    
    // we don't pop() but use the previous transformation to draw the next face
    rotateX(PI); // these were not obvious to me, actually this code conciseness was found afterwards when cleaning up the code
    rotateZ(PI); // these unfolding transforms are the first thing I worked on when implementing the animation
    rotateX(PI);
    unfoldAndDrawFace(p); // that's drawing the face that doesn't touch the floor face
    pop();
    
    push();
    rotateZ(2*HALF_PI);
    unfoldAndDrawFace(p);
    pop();
    
    push();
    rotateZ(3*HALF_PI);
    unfoldAndDrawFace(p);
    pop();
  }
  
  void show()
  {
    // below, correct (x,y) in function of (i,j) for the working tiling pattern
    // works with the later code that rotates or not the drawing in function of i % 2
    float x = 2 * j * L + (i%2==0?0:L);
    float y = j * L + (i%2==0?0:4*L) + floor(i/2.0) * 6 * L;
    // (wasn't obvious to me, had to use pen and paper)
    
    
    float offset = atan2(y,x)/TAU; // angle delay here, a nice line of code to play with
    // related: tutorial for propagation of periodic function: https://bleuje.com/tutorial2/
    float p = map(cos(TAU*(t-offset)),-0.65,0.65,0,1,true); // (technique: cosine with saturation to keep the periodic function at 0 or 1 for some time)
    // p is the state/progress of the cube unfolding (1 is unfolded, 0 is cube state)
    
    truchetActivation = ease(c01(10*p),2.0); // minor glitch fix thing, hiding the truchet arcs in closed cube state with truchetActivation = 0, and there is a fast transition to be quickly back at 1 in function of p
    
    push();
    translate(x,y);
    
    if(i % 2 == 0)
    {
      showUnfold(p);
    }
    else
    {
      rotateZ(PI); // rotation for tiling pattern
      showUnfold(p);
    }
    pop();
  }
}

// draw square tiles everywhere on the floor, with same style/function as cube faces
void drawFloorGrid()
{
  for(int i=-nGridSize;i<=nGridSize;i++)
  {
    for(int j=-nGridSize;j<=nGridSize;j++)
    {
      float x = i * L;
      float y = j * L;
      
      push();
      translate(x,y);
      drawSquareWithCustomContour();
      pop();
    }
  }
}

ArrayList<Cube> cubes;

PFont chosenFont;

void setup()
{
  size(800,800,P3D);
  result = new int[width*height][3];
  smooth(8);
  ortho(); // isometric view activated

  chosenFont = createFont("ChakraPetch-Medium.ttf", 128);
  textFont(chosenFont);
  
  cubes = new ArrayList<Cube>();
  
  for(int i=-nCubesGrid;i<=nCubesGrid;i++)
  {
    for(int j=-nCubesGrid;j<=nCubesGrid;j++)
    {
      cubes.add(new Cube(i,j));
    }
  }
}


void draw_()
{
  background(0);
  push();
  translate(width/2,height/2,-1000); // drawing far from camera to avoid glitch when stuff is too close to camera
  // (because of ortho(), it doesn't affect drawing other than correcting glitch)
  
  scale(800.0/600); // it was coded for width and height = 600, now rescaling for other resolution (800)
  
  // camera view...
  rotateX(0.307*PI); // angle that works for the good "optical illusion"/clean cubes layout that blends with floor grid
  rotateZ(0.75*PI);
  
  drawFloorGrid();
  
  for(Cube cube : cubes)
  {
    cube.show();
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
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
