// Processing code by Etienne Jacob
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/permutationpatternspropagation/

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
    t = (mouseX*1.3/width)%1;
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

    saveFrame("fr###.png");
    //saveFrame("png/fr#####.png");
    println(frameCount,"/",numFrames);
    if (frameCount==numFrames)
      exit();
  }
}

//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 6;
int numFrames = 100;        
float shutterAngle = 1.8;

boolean recording = false;

int gridSize = 32;

// for each position (i,j) find the next position (for example (i+1,j))
// mainType is the type of pattern (0, 1 or 2)
// this is a bit similar to fragment shader coding where we return color in function of pixel position
PVector nextPositionField(int mainType,int i,int j)
{
  if(mainType==0||mainType==1) // patterns : set of "slices"
  {
    int subSize = (mainType==0?4:32); // separating the patterns into squares of size subSize
    int subType = ((i/subSize) + (j/subSize))%2; // getting different types with which square we're into
    int ISubSize = (subType==0?2:subSize);
    int JSubSize = (subType==1?2:subSize);
    int localI = i%ISubSize;
    int localJ = j%JSubSize;
    if(subType==0)
    {
      // see sliceNextPosition below, a function defined for code factorization
      return sliceNextPosition(localI,localJ,i,j,subSize);
    }
    else // for the other type, same thing but rotated
    {
      PVector v = sliceNextPosition(localJ,localI,j,i,subSize); // (notice the swap between localI and localJ)
      return new PVector(v.y,v.x); // (swap)
    }
  }
  else if(mainType==2) // pattern: concenctric squares with alternating direction
  {
    int subSize = 16; // separating the patterns into squares of size subSize
    int subType = ((i/subSize) + (j/subSize))%2; // getting different types with which square we're into
    int localI = i%subSize;
    int localJ = j%subSize;
    float localI_Middle = float(subSize-1)/2; // middle in the main current square, on x axis, to find the center of concentric turning squares
    float localJ_Middle = float(subSize-1)/2; // middle in the main current square, on y axis, to find the center of concentric turning squares
    float angleToLocalCenter = atan2(localJ-localJ_Middle,localI-localI_Middle); // now we can get our angle to the square
    float d = max(abs(localI_Middle-localI),abs(localJ_Middle-localJ)); // distance to local center with infinity norm (points at same distance form a square)
    // now lets find the next positions
    float eps=0.001; // small angle to manage particles on corners of the turning square and give them the right direction
    if(round(d)%2==subType) // if branching based on distance to center for alternating direction, also uses the subType to change direction for different centers
    { // now cutting the turning square into
      if((angleToLocalCenter>=-HALF_PI-QUARTER_PI-eps)&&(angleToLocalCenter<=-HALF_PI+QUARTER_PI-eps)) return new PVector(i+1,j);
      if((angleToLocalCenter>=-HALF_PI+QUARTER_PI-eps)&&(angleToLocalCenter<=QUARTER_PI-eps)) return new PVector(i,j+1);
      if((angleToLocalCenter>=QUARTER_PI-eps)&&(angleToLocalCenter<=QUARTER_PI+HALF_PI-eps)) return new PVector(i-1,j);
      else return new PVector(i,j-1);
    }
    else // same thing as previous if branch but opposite direction
    {
      if((angleToLocalCenter>=-HALF_PI-QUARTER_PI+eps)&&(angleToLocalCenter<=-HALF_PI+QUARTER_PI+eps)) return new PVector(i-1,j);
      if((angleToLocalCenter>=-HALF_PI+QUARTER_PI+eps)&&(angleToLocalCenter<=QUARTER_PI+eps)) return new PVector(i,j-1);
      if((angleToLocalCenter>=QUARTER_PI+eps)&&(angleToLocalCenter<=QUARTER_PI+HALF_PI+eps)) return new PVector(i+1,j);
      else return new PVector(i,j+1);
    }
  }
  return new PVector(0,0); // dummy value that will never be returned because we will always have a mainType of 0, 1 or 2 and fall into previous ifs
}



// "slices" pattern :
/* the slices looks like this, the rotation direction changes every other slice

--  -- 
||  ||
||  ||
||  ||
||  ||
--  --

*/
// a and b are "local" i and j, i and j are the global position
PVector sliceNextPosition(int a,int b,int i, int j,int Height)
{
    if((i/2)%2==0) // "every other slice"
    {
      // in the 4 following lines, hard coded next positions on the 4 corner positions (top and bottom of the slice)
      if((b==0)&&(a%2==0)) return new PVector(i+1,j);
      if((b==0)&&(a%2==1)) return new PVector(i,j+1);
      if((b==Height-1)&&(a%2==0)) return new PVector(i,j-1);
      if((b==Height-1)&&(a%2==1)) return new PVector(i-1,j);
      // for other positions just go down or up depending on the side we're on
      if(a%2==0) return new PVector(i,j-1);
      if(a%2==1) return new PVector(i,j+1);
    }
    else // same as previous case but other direction
    {
      if((b==0)&&(a%2==0)) return new PVector(i,j+1);
      if((b==0)&&(a%2==1)) return new PVector(i-1,j);
      if((b==Height-1)&&(a%2==0)) return new PVector(i+1,j);
      if((b==Height-1)&&(a%2==1)) return new PVector(i,j-1);
      
      if(a%2==0) return new PVector(i,j+1);
      if(a%2==1) return new PVector(i,j-1);
    }
    return new PVector(0,0);
}

int numPositionsPerMove = 3; // 3 means we go 2 positions further using the current next positions pattern
int numberOfPatterns = 3;
float transitionTime = 0.27; // fraction of time used for each particle move. Because we have 3 patterns so 3 moves, it can't be larger than 1/3 = 0.333333
// (also has to be smaller than 1/3 due to position change that can create a move request earlier than the one on position before move)

float iterationsPerCycle = 2000; // simulation quality. timeStep = 1.0/iterationsPerCycle later;
int numberOfRepeats = 4; // repeating the loop many times to try to achieve stability and perfect looping
float time = 0; // will be incremented during simulation


// class to have the list of positions of each move,
// and a function ("unMappedPosition") to give the continuous change of position from continuous time
class Move
{
  int start_i;
  int start_j;
  int type;
  float startTime,endTime;
  PVector endPos;
  
  PVector [] path = new PVector[numPositionsPerMove];
  
  Move(PVector startPos,int type_,float tm)
  {
    start_i = round(startPos.x);
    start_j = round(startPos.y);
    type = type_;
    startTime = tm;
    endTime = startTime+transitionTime;
    
    
    // finding the move's path iteratively, using the next positions field...
    int curi = start_i;
    int curj = start_j;
    for(int k=0;k<numPositionsPerMove;k++)
    {
      path[k] = new PVector(curi,curj);
      PVector v = nextPositionField(type,curi,curj);
      curi = round(v.x);
      curj = round(v.y);
    }
    endPos = path[numPositionsPerMove-1];
  }
  
  // position in function of time "unmapped" because it's not mapped to pixel position yet
  // as usual it's done with linear interpolation between the positions of the list
  PVector unMappedPosition(float time_)
  {
    float p = constrain(map(time_,startTime,endTime,0,1),0,1);
    float q = ease(p,1.6);
    float ind = 0.999999*q*(numPositionsPerMove-1);
    int ind1 = floor(ind);
    int ind2 = ind1+1;
    float frac = ind-ind1;
    
    PVector v1 = path[ind1];
    PVector v2 = path[ind2];
    
    PVector u = v1.copy().lerp(v2,frac);
    
    return u;
  }
}

// wave that triggers moves
// after more done moves the moves have to be triggered later, hence the  additional +1.0*numberOfDoneMoves/numberOfPatterns
float triggerer(PVector pos,int numberOfDoneMoves)
{
  return  0.03*dist(pos.x,pos.y,float(gridSize-1)/2.0,float(gridSize-1)/2.0)+1.0*numberOfDoneMoves/numberOfPatterns;
}

float margin = 20;

PVector convertToPixelPosition(float i,float j)
{
  return new PVector(map(i,0,gridSize-1,-width/2+margin,width/2-margin),map(j,0,gridSize-1,-height/2+margin,height/2-margin));
}

class Particle
{
  boolean isMoving = false;
  int doneMoves = 0;
  PVector currentPos;
  
  Particle(PVector pos_)
  {
    currentPos = pos_;
  }
  
  Move currentMove;
  
   // positions computer through the simulation :
  ArrayList<PVector> positions = new ArrayList<PVector>(); // not in pixels, just with grid indices
  
  void update() // simulation update
  {
    // if we're not moving we check is the waves trigger a new move
    if(!isMoving && time >= triggerer(currentPos,doneMoves))
    {
      currentMove = new Move(currentPos,doneMoves%numberOfPatterns,time);
      isMoving = true;
      doneMoves++;
    }
    else if(isMoving && time >= currentMove.endTime) // if we were moving we check if we're now past the move's endTime, in this case we set isMoving to false
    {
      isMoving = false;
      currentPos = currentMove.endPos;
    }
    
    // now adding the current position to the list
    if(!isMoving)
    {
      positions.add(currentPos);
    }
    else
    {
      positions.add(currentMove.unMappedPosition(time)); // when we're moving, the Move class has a member function to give position in function of time
    }
  }
  
  
  
   // show() using the list of positions from simulation to get position at any time of the loop,
   // with linear interpolation,
   // using positions of the last cycle of the simulation
  void show()
  {
    float t2 = (t+(numberOfRepeats-1))*0.9999999;
    float ifl = iterationsPerCycle*t2;
    int i1 = floor(ifl);
    int i2 = i1+1;
    float lp = ifl-i1;
    
    PVector v1 = positions.get(i1);
    PVector v2 = positions.get(i2);
    
    PVector u = v1.copy().lerp(v2,lp);
    
    PVector pixelPos = convertToPixelPosition(u.x,u.y);
    
    // design : drawing the particle with an ellipse with a smaller white dot inside it
    stroke(255);
    strokeWeight(1.5);
    fill(0);
    ellipse(pixelPos.x,pixelPos.y,12,12);
    
    strokeWeight(2.6);
    point(pixelPos.x,pixelPos.y);
  }
}

Particle [][] array = new Particle[gridSize][gridSize];

void simulate()
{
  println("Starting simulation...");
  float timeStep = 1.0/iterationsPerCycle;
  for(int k=0;k<iterationsPerCycle*numberOfRepeats+100;k++)
  {
    for(int i=0;i<gridSize;i++)
    {
      for(int j=0;j<gridSize;j++)
      {
        array[i][j].update();
      }
    }
    time += timeStep;
  }
  println("Finished simulation.");
}

void setup()
{
  size(800,800,P2D);
  result = new int[width*height][3];
  
  for(int i=0;i<gridSize;i++)
  {
    for(int j=0;j<gridSize;j++)
    {
      array[i][j] = new Particle(new PVector(i,j));
    }
  }
  
  simulate();
}



void draw_()
{
  background(0);
  push();
  translate(width/2,height/2);
  
  for(int i=0;i<gridSize;i++)
  {
    for(int j=0;j<gridSize;j++)
    {
      array[i][j].show();
    }
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
