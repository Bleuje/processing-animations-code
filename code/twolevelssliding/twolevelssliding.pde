// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/twolevelssliding/

// quite long code, but quite straighforward algorithm

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
int numFrames = 340;        
float shutterAngle = 0.85;

boolean recording = false;

// IDEA : have a grid with a small hole evolving in it,
// duplicate the grid with replacement technique to get a larger grid with big holes

ArrayList<PVector> mainPath = new ArrayList<PVector>();

int largeGridSize = 7;
int numberOfSimulationSteps = 1700; // simulation steps for small squares movements
int smallSquareGridSize = 6;

// small square
class SmallSquare
{
  PVector [] positions = new PVector[numberOfSimulationSteps+1];
}

// an instance of this shows the whole thing, and there's only one instance so a class was not necessary
class System
{
  SmallSquare [] smallSquares = new SmallSquare[smallSquareGridSize*smallSquareGridSize];
  
  int [][] indexAtPos = new int[smallSquareGridSize][smallSquareGridSize];
  
  PVector holePos;
  
  System()
  {
    holePos = new PVector(floor(random(smallSquareGridSize)),floor(random(smallSquareGridSize)));
    
    int k = 0;
    for(int i=0;i<smallSquareGridSize;i++)
    {
      for(int j=0;j<smallSquareGridSize;j++)
      {
        if(abs(holePos.x-i)>0.001 || abs(holePos.y-j)>0.001)
        {
          smallSquares[k] = new SmallSquare();
          smallSquares[k].positions[0] = new PVector(i,j); // initial position in grid
          indexAtPos[i][j] = k; // storing that at (i,j) we have the k-th smallSquare
          k++;
        }
      }
    }
    
    PVector comingFrom = new PVector(-100,-100); // dummy initial value for an (i,j) position in grid
    // this is used to avoid to have the small hole go back to its previous position
    
    // simulation in which we move the small hole of the grid and update the small squares positions
    for(int stepIndex=0;stepIndex<numberOfSimulationSteps;stepIndex++)
    {
      boolean availablePositionWasNotFound = true;
      
      PVector previousHolePos = holePos;
      
      while(availablePositionWasNotFound)
      {
        int direction = floor(random(4)); // random direction to look for available position
        
        boolean found = false;
        PVector target = new PVector(1234,1234); // dummy initial value
        
        if(direction==0)
        {
          target = new PVector(holePos.x-1,holePos.y);
          // we must not go back to previous hole position
          if(round(target.x)==round(comingFrom.x)&&round(target.y)==round(comingFrom.y))
            continue;
          // the hole must stay inside the grid
          if(target.x<0||target.x>=smallSquareGridSize)
            continue;
          // (continue implies going dreictly to next wile loop step)
          found = true;
        }
        if(direction==1)
        {
          target = new PVector(holePos.x+1,holePos.y);
          if(round(target.x)==round(comingFrom.x)&&round(target.y)==round(comingFrom.y))
            continue;
          if(target.x<0||target.x>=smallSquareGridSize)
            continue;
          found = true;
        }
        if(direction==2)
        {
          target = new PVector(holePos.x,holePos.y-1);
          if(round(target.x)==round(comingFrom.x)&&round(target.y)==round(comingFrom.y))
            continue;
          if(target.y<0||target.y>=smallSquareGridSize)
            continue;
          found = true;
        }
        if(direction==3)
        {
          target = new PVector(holePos.x,holePos.y+1);
          if(round(target.x)==round(comingFrom.x)&&round(target.y)==round(comingFrom.y))
            continue;
          if(target.y<0||target.y>=smallSquareGridSize)
            continue;
          found = true;
        }
        
        if(found)
        {
          PVector aux = holePos;
          holePos = target;
          previousHolePos = aux;
          availablePositionWasNotFound = false;
        }
      }
      
      int smallSquareIndexAtHole = indexAtPos[round(holePos.x)][round(holePos.y)];
      // (we haven't moved the small squares yet)
      
      // we update indexAtPos because this small square takes the position of the previous hole position
      indexAtPos[round(previousHolePos.x)][round(previousHolePos.y)] = smallSquareIndexAtHole;
      // we update the position of the hole at the simulation step
      smallSquares[smallSquareIndexAtHole].positions[stepIndex+1] = previousHolePos;
      // we update the positions of the other small squares (it stays the same)
      for(int e=0;e<(smallSquareGridSize*smallSquareGridSize-1);e++)
      {
        if(e!=smallSquareIndexAtHole)
        {
          smallSquares[e].positions[stepIndex+1] = smallSquares[e].positions[stepIndex];
        }
      }
      
      comingFrom = previousHolePos;
    }
    
  }
  
  
  
  void showGrid(float p) // p progressing in range [0,1]
  {
    p = lerp(p,ease(p,1.8),0.6); // easing mixed with no easing
    // this easing makes holes move faster in the center
    
    // preparing linear interpolation for small squares movement (but most won't move because we interpolate between two same positions)
    float floatIndex = 0.9999*numberOfSimulationSteps*p;
    int stepIndex1 = floor(floatIndex);
    int stepIndex2 = stepIndex1+1;
    float frac = floatIndex-stepIndex1;
    
    for(int e=0;e<(smallSquareGridSize*smallSquareGridSize-1);e++)
      {
        PVector pos1 = smallSquares[e].positions[stepIndex1];
        PVector pos2 = smallSquares[e].positions[stepIndex2];
        PVector pos = pos1.copy().lerp(pos2,ease(frac,1.7)); // interpolation done, easing for smooth movement
        
        // converting to pixel position
        pos.add(new PVector(-smallSquareGridSize/2.0+0.5,-smallSquareGridSize/2.0+0.5));
        float A = 14.25;
        pos.mult(A);
        
        // drawing one small square
        push();
        translate(pos.x,pos.y);
        fill(0);
        rectMode(CENTER);
        stroke(255);
        strokeWeight(1.75);
        rect(0,0,9,9);
        pop();
      }
  }
  
  // interpolation between two main path positions, with easing
  PVector mainPathPos(float p) // here p is in range [0,1]
  {
    float floatIndex = p*(mainPath.size()-1)*0.999999;
    int ind1 = floor(floatIndex);
    int ind2 = ind1+1;
    float frac = floatIndex-ind1;
    
    PVector pos1 = mainPath.get(ind1);
    PVector pos2 = mainPath.get(ind2);
    
    float interp = ease(constrain(9*frac,0,1),2.2); // we stop for a long time after moving
    
    return pos1.copy().lerp(pos2,interp);
  }
  
  PVector mainPathPosToPixelPos(PVector integerPos)
  {
    float px = map(0.5+integerPos.x,0,largeGridSize,-width/2,width/2);
    float py = map(0.5+integerPos.y,0,largeGridSize,0-height/2,height/2);
    return new PVector(px,py);
  }
  
  void show(float p)
  {
    PVector pos = mainPathPos(p);
    PVector pixelPos = mainPathPosToPixelPos(pos); // (i,j) to pixel position

    push();
    translate(pixelPos.x,pixelPos.y);
    showGrid(p);
    pop();
  }
  
  // replacement technique
  int numberOfDrawnGrids = mainPath.size()-5; // (with replacement technique)
  void show()
  {
    for(int i=0;i<numberOfDrawnGrids;i++) show((i+t)/numberOfDrawnGrids);
  }
}

System system;

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  smooth(8);
  
  // constructing the main path "by hand"
  mainPath.add(new PVector(-1,0));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(i,0));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(largeGridSize-i-1,1));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(i,2));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(largeGridSize-i-1,3));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(i,4));
  for(int i=0;i<largeGridSize;i++) mainPath.add(new PVector(largeGridSize-i-1,5));
  for(int i=0;i<=largeGridSize;i++) mainPath.add(new PVector(i,6));
  
  system = new System();
}


void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  system.show();

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
