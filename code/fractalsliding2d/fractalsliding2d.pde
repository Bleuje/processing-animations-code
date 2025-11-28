// Processing code by Etienne JACOB
// for collab with Yann Le Gall (https://demozoo.org/graphics/322553/)
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/2dfractalslidingsquares/

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

float c01(float x)
{
  return min(1,max(0,x));
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
int numFrames = 175;        
float shutterAngle = 1.0;

boolean recording = false; // if false, time is controlled by mouse X

int MAX_DEPTH = 9; // maximum recursion depth
float L; // L = width/2; in setup()

// tree structure
class Structure
{
  int numberOfChildren = 3;
  Structure [] children = new Structure[numberOfChildren];
  int depth;
  int childIndex;
  boolean isMain; // true if it ends up in top left corner
  float offset;
  float splitDelay;
  float direction; // square path orientation
  
  Structure(int index_,int depth_,boolean isMain_,float offset_,float splitDelay_,float direction_)
  {
    childIndex = index_;
    depth = depth_;
    isMain = isMain_;
    offset = offset_;
    splitDelay = splitDelay_;
    direction = direction_;
    float nextOffsets = isMain?0:random(1);
    float nextSplitDelay = isMain?0:(1-pow(random(1),3.0))*2-1;
    float nextDirection = isMain?1:floor(random(0,2))*2-1;
    
    if(depth<MAX_DEPTH)
    {
      for(int i=1;i<numberOfChildren;i++)
      {
        children[i] = new Structure(i,depth+1,false,nextOffsets,nextSplitDelay,nextDirection);
      }
      children[0] = new Structure(0,depth+1,isMain,nextOffsets,nextSplitDelay,nextDirection);
    }
  }
  
  // square path, using polar coordinates, maybe not the best choice :)
  // also has easing to make the movement stop
  PVector path0(float q)
  {
    q = ((q%1)+1)%1; // making sure q is in [0,1[
    float floatIndex = 4*q;
    int index1 = floor(floatIndex);
    int index2 = index1+1;
    float angle1 = index1*HALF_PI+QUARTER_PI-PI;
    float angle2 = index2*HALF_PI+QUARTER_PI-PI;
    
    float fr = floatIndex-index1; // fractional part of floatIndex
    float es = ease(c01(fr*4),2.5); // classic easing + moving and stopping with the constrain (c01)
    float radius = 2/sqrt(2);
    PVector v1 = new PVector(cos(angle1)*radius,sin(angle1)*radius); // fixed position 1 to define path
    PVector v2 = new PVector(cos(angle2)*radius,sin(angle2)*radius); // fixed position 2 to define path
    // interpolate between fixed positions with easing
    PVector v = v1.copy().lerp(v2,(float)es);
    return v;
  }
  
  // offset on previous path
  PVector path1(float q)
  {
    float q2 = q-float(childIndex)/numberOfChildren-0.05+offset;
    // (childIndex/3 is the correct offset to have the 3 children evenly at different places of the path)
    return path0(q2*direction);
  }
  
  PVector path2(float q)
  {
    // using pow to make the movement slower and slower
    // also using the min function to stop moving completely
    return path1(-pow(-min(0,q*0.2),2.5));
  }
  
  void show(float p,int maxDepth2) // maxDepth2 is used to stop the recursion, it can be different from MAX_DEPTH
  {
    stroke(255);
    noFill();
    strokeWeight(5.8*(float)c01(-1.0-1.3*p));
    rectMode(CENTER);
    rect(0,0,L*2,L*2);
    float param = depth-t+2-splitDelay-maxDepth2;
    if(param>=0) // if true, stop recursion
    {
      if(childIndex==0) // only show if it's a child 0 (not clean :( )
      {
        // drawing a dot...
        float reduce = constrain(map(param,0.1,0,1,0),0,1)*1.15; // size change parameter if we're close to splitting
        strokeWeight(0.95*L*reduce);
        stroke(255);
        point(0,0);
      }
    }
    else
    {
      float growth = pow(constrain(map(param,0,-0.1,0,1),0,1),1.7); // size change parameter if we're close to splitting
      PVector pos = path2(p);
      pos.mult(0.5*L);
      push();
      translate(pos.x,pos.y);
      
      scale(0.5); // with this scale change during recursions, we don't have to adjust pixel positions with factors
      scale(growth); // just for splitting, generally at one, no scale change here
      
      // to show yourself you show your children "one loop time ago" (p-1)
      for(int i=1;i<numberOfChildren;i++)
      {
        children[i].show(p-1,maxDepth2);
      }
      if(isMain)
      {
        // a square that ends in the top left corner is treated differently
        // you show yourself in the past (one loop ago)
        // and decrease the max depth argument by one
        show(p-1,maxDepth2-1);
        // arguably the trickiest thing in the entire code
      }
      else // child 0 is not a isMain
      {
        children[0].show(p-1,maxDepth2);
      }
      pop();
    }
  }
}

Structure mainStructure;

void setup(){
  size(650,650,P2D);
  result = new int[width*height][3];
  
  randomSeed(92645);
  
  mainStructure = new Structure(0,0,true,0,0,1);
  
  L = width/2;
  
  smooth(8);
}


void draw_(){
  background(0);
  push();
  scale(pow(2.0,t)*2*1.003);
  translate(width/2,height/2);
  
  mainStructure.show(t-0.5,MAX_DEPTH);
  
  pop();
}


/* License:
 *
 * Copyright (c) 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
