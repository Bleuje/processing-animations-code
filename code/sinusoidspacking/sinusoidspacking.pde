// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

//-----------------------------------

void draw() {
  if (!recording) // test mode...
  {
    t = (mouseX*1.3/width)%1;
    c = mouseY*1.0/height;
    if (mousePressed)
      println(c);
    draw_();
  } else // render mode...
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
      println(frameCount, "/", numFrames);
    }

    if (frameCount==numFrames)
      stop();
  }
}

// End of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 5;
int numFrames = 130;
float shutterAngle = .6;

boolean recording = false;


int NumberOfIterations = 1000;

int currentNumberOfCircles = 0;

void setup() {
  size(600, 600, P2D);
  result = new int[width*height][3];
  smooth(8);

  randomSeed(545);

  // circle packing setup, see functions after Circle class implementation
  for (int k=0; k<NumberOfIterations; k++) {
    circlePackingIteration();
    println(currentNumberOfCircles, "/", NumberOfIterations);
  }
}

class Circle {
  int id; // circle index/id

  // position
  float x;
  float y;

  float r; // radius, will be updated

  boolean growing = true;
  float growthRate;

  // parameters for random drawing style (dots on moving sinusoid)
  float timeSign = 2*floor(random(2)) - 1;
  float timeOffset = random(1);
  int speed = 1 + floor(pow(random(0, 1), 2.0)*1.5);
  float showAngle = random(TWO_PI);
  int numberOfSinPeriods;
  int numberOfSinPoints;

  Circle(int i) {
    id = i;

    boolean foundPosition = false;

    // loop until a random try is on free position
    while (!foundPosition) {
      float rPos = 200 * sqrt(random(1));
      float thetaPos = random(TWO_PI);

      float xTry = rPos*cos(thetaPos);
      float yTry = rPos*sin(thetaPos);

      if (!positionIsInsideCircle(xTry, yTry, id)) {
        x = xTry;
        y = yTry;
        foundPosition = true;
        r = 0;

        // these parameters are defined here because we could use x and y to define them
        growthRate = 1.3;
        numberOfSinPeriods = floor(2+35*pow(random(0, 1), 3.0));
        numberOfSinPoints = floor(random(22, 130));
      }
    }
  }

  void grow() {
    if (growing) r += growthRate;
  }

  void show() {
    float sinTime = (1234 + timeSign*t + timeOffset)%1;

    push();
    translate(x, y);
    scale(0.75); // spacing effect of the packing here
    rotate(showAngle);

    for (int k=0; k<=numberOfSinPoints; k++) {
      float localX = map(k, 0, numberOfSinPoints, -r, r);

      float normalizedX = localX/r;
      float angle = TWO_PI*(normalizedX*numberOfSinPeriods + sinTime*speed); // (input of the sinusoid: angle progressing with x and with time)

      float localY = r * sqrt(1-normalizedX*normalizedX) * sin(angle); // (the sqrt stuff makes an envelope to the sinusoid, with circle shape)
      float localZ = r * cos(angle);

      float heightColorFactor = map(cos(angle), -1, 1, 0.4, 1.0);
      float sizeSWFactor = pow((map(r, 0, 10, 0.35, 1)), 0.5)*2;

      // stroke weight with lighting from sphere normal...
      PVector v = new PVector(localX, localY, localZ);
      float ux = v.x*cos(showAngle) - v.y*sin(showAngle);
      float uy = v.x*sin(showAngle) + v.y*cos(showAngle);
      PVector u = (new PVector(ux, uy, localZ)).normalize();
      PVector lightDir = (new PVector(1, -1, 0.5)).normalize();
      float dotProduct = u.dot(lightDir);
      float lightingSWFactor = map(dotProduct, -1, 1, 0.1, 1.3);


      strokeWeight(sizeSWFactor * lightingSWFactor);
      stroke(255, 310 * heightColorFactor);

      point(localX, localY);
    }

    pop();
  }
}

Circle[] circlesArray = new Circle[NumberOfIterations];

// At each iteration of the algorithm, make a new circle (its random free position will be found),
// then grow all current circles at their growth rate if they are still in growing mode,
// then stop growing mode for all growing circles that touch others.
void circlePackingIteration() {
  addCircle();

  for (int i=0; i<currentNumberOfCircles; i++) {
    circlesArray[i].grow();
  }

  stopGrowthCheck();
}

boolean positionIsInsideCircle(float x, float y, int id) {
  for (int i=0; i<currentNumberOfCircles; i++) {
    if (i!=id && dist(x, y, circlesArray[i].x, circlesArray[i].y) <= circlesArray[i].r+1) {
      return true;
    }
  }
  return false;
}

// Check all pairs of circles, if one circle of a pair is growing,
// check if it touches the other circle, if true stop its growing mode
void stopGrowthCheck() {
  for (int i=0; i<currentNumberOfCircles; i++) {
    for (int j=0; j<i; j++) {
      if ((circlesArray[i].growing) || (circlesArray[j].growing)) {
        float distanceBetweenCircles = dist(circlesArray[j].x, circlesArray[j].y, circlesArray[i].x, circlesArray[i].y);
        if (distanceBetweenCircles <= (circlesArray[i].r+circlesArray[j].r) + 1) {
          circlesArray[i].growing = false;
          circlesArray[j].growing = false;
        }
      }
    }
  }
}


void addCircle() {
  if (currentNumberOfCircles < NumberOfIterations) {
    circlesArray[currentNumberOfCircles] = new Circle(currentNumberOfCircles);
    currentNumberOfCircles++;
  }
}

void draw_() {
  push();
  background(0);
  translate(width/2, height/2);

  scale(600.0/500);

  for (int i=0; i<currentNumberOfCircles; i++) {
    circlesArray[i].show();
  }

  pop();
}

/* License:
 *
 * Copyright (c) 2018, 2024 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
