// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// result here : https://bleuje.com/gifanimationsite/single/fluidsphereobstacle/

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

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

int samplesPerFrame = 4; // icnrease that for super high quality motion blur
int numFrames = 30;        
float shutterAngle = .75;

boolean recording = false;

// IDEA : simulation with constant speed field + a repulsive field, then just put this black sphere at a good place and size

int numberOfPaths = 100000;
int numberOfSimulationSteps = 50;
float timeStep = 0.3;

// class for a center of repulsion, here we will actually have only one instance
class Center
{
  float x,y;

  float repulseIntensity;
  
  Center(float x_,float y_,float r)
  {
    x = x_;
    y = y_;
    repulseIntensity = r;
  }
  
  void show()
  {
    stroke(255,0,0);
    strokeWeight(3);
    point(x,y);
  }
}

Center repulsionCenter;

class Path
{
  // random start positions
  float currentX = random(-width,2*width);
  float currentY = lerp(1.3*height,-height,pow(random(1),5));
  
  ArrayList<PVector> positions = new ArrayList<PVector>(); // list of recorded positions with simulation
  
  float sw = random(1,2); // strokeWeight parameter
  int numberOfParticlesOnPath = 3;
  float tOffset = random(1); // particles of different paths don't start at the same time thanks to this offset
  
  Path()
  {
    positions.add(new PVector(currentX,currentY));
  }
  
  void update()
  {
    PVector velocity = field(currentX,currentY);
    currentX += timeStep*velocity.x;
    currentY += timeStep*velocity.y;
    positions.add(new PVector(currentX,currentY));
  }
  
  void show()
  {
    strokeWeight(sw);
    float tt = (t+tOffset)%1; // particles don't start at the same time on different paths
    int arrayLength = positions.size();
    
    // replacement technique on path with numberOfParticlesOnPath particles
    // and linear interpolation between positions recorded during simulation
    for(int i=0;i<numberOfParticlesOnPath;i++)
    {
      float floatIndex = map(i+tt,0,numberOfParticlesOnPath,0,arrayLength-1)*0.999999; // mapping from numberOfParticlesOnPath range to recorded positions range
      // 0.99999 factor to make sure that the index2 below won't go out of array bounds
      
      int index1 = floor(floatIndex);
      int index2 = index1+1;
      float interp = floatIndex - floor(floatIndex);
      PVector pos = positions.get(index1).copy().lerp(positions.get(index2),interp);
      
      float p = floatIndex/(arrayLength-1); // p in [0,1] indicates the progression on the path
      float alpha = 255*pow(constrain(sin(PI*p),0,1),0.25); // more alpha at the center of the path (sin(PI*x) is 0 at x=0 and x=1 and 1 at x=0.5)
      stroke(255,alpha);

      point(pos.x,pos.y);
    }
  }
}

Path[] pathsArray = new Path[numberOfPaths];

// "velocity field" / "flow field"
PVector field(float x,float y)
{
  float repulsionAmount = 20;
  float noiseAmount = 15;
  
  // starting with large constant velocity
  PVector velocitySum = new PVector(15,-30);
  
  // repulstion field...
  PVector centerPos = new PVector(repulsionCenter.x,repulsionCenter.y);
  PVector vecFromCenterToPos = (new PVector(x,y)).sub(centerPos);
  float distance = vecFromCenterToPos.mag();
  vecFromCenterToPos.normalize(); // vecFromCenterToPos goes from the center position to (x,y) (normalized)
 
  float intensity = constrain(map(distance,0,width,1,0),0,1); // mapping of distance to intensity, most intensity when distance is zero
  intensity = pow(intensity,25)*repulsionAmount; // transforming the curve of intensity in function of distance with pow and amount1
  // (much larger intensity closer to the center)
  
  PVector centerEffect = vecFromCenterToPos.mult(repulsionCenter.repulseIntensity * intensity);
  
  velocitySum.add(centerEffect);
  
  // small layer of noise (velocity field distortion)
  float noiseScale = 0.05;
  float noiseValueX = noiseAmount*(noise(100+noiseScale*x,100+noiseScale*y)-0.5);
  float noiseValueY = noiseAmount*(noise(200+noiseScale*x,200+noiseScale*y)-0.5);
  velocitySum.add(new PVector(noiseValueX,noiseValueY));
  
  return velocitySum;
}

void computePathsStep()
{
  for(int i=0;i<numberOfPaths;i++)
  {
    pathsArray[i].update();
  }
}

void setup()
{
  size(500,500,P3D);
  result = new int[width*height][3];
  background(0);
  
  repulsionCenter = new Center(0.5*width,0.4*height,5);
  
  for(int i=0;i<numberOfPaths;i++)
  {
    pathsArray[i] = new Path();
  }
  
  // simulation done in setup()
  for(int i=0;i<numberOfSimulationSteps;i++)
  {
    println("simulation step : ",i+1);
    computePathsStep();
  }
}



void draw_()
{
  background(0);
  push();

  translate(0,50,0);
  rotateX(0.95);
  
  // draw particles
  for(int i=0;i<numberOfPaths;i++)
  {
    pathsArray[i].show();
  }
  
  // draw sphere
  float sphereRadius = 6.6*repulsionCenter.repulseIntensity;
  push();
  translate(repulsionCenter.x+4,repulsionCenter.y-12);
  fill(0);
  noStroke();
  sphere(sphereRadius);
  pop();
  
  pop();
}


/* License:
 *
 * Copyright (c) 2017, 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
