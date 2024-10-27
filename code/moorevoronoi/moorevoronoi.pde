// Processing code by Etienne Jacob
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.

//////////////////////////////////////////////////////////////////////////////
// Start of template

int[][] result; // pixel colors buffer for motion blur
float t; // time global variable in [0,1[
float c; // other global variable for testing things, controlled by mouse

//-----------------------------------
// some generally useful functions...

// ease in and out, [0,1] -> [0,1], with a parameter g:
// https://patakk.tumblr.com/post/88602945835/heres-a-simple-function-you-can-use-for-easing
float ease(float p, float g) {
  if (p < 0.5)
    return 0.5 * pow(2*p, g);
  else
    return 1 - 0.5 * pow(2*(1 - p), g);
}

//-----------------------------------

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

int samplesPerFrame = 1;
int numFrames = 200;
float shutterAngle = 1.0;

boolean recording = false;

// parameters to play with:
int numberOfHoles = 32; // number of missing points in the Moore curve grid of points
float moveSpeedFactor = 8; // making the points move more or less fast
// meaning a point stops after moving fast to next grid position
// so making them move faster can actually mean less area of movement in the overall image

int numberOfPoints = 16*16 - numberOfHoles;

// using functions in moore.pde
// position on the Moore curve from p in [0, curveSize * curveSize]
// just interpolating between positions of the Moore curve's vertices positions
PVector moorePosition(float p) {
  int index1 = floor(p);
  int index2 = index1+1;

  float gridPosLerp = p - index1; // fractional part between the 2 grid indices
  gridPosLerp = min(moveSpeedFactor*gridPosLerp,1.0); // this min makes the points stop
  gridPosLerp = ease(gridPosLerp, 2.0); // easing for smoother movement

  PVector intGridPos1 = getMooreIntegerPosition(index1);
  PVector intGridPos2 = getMooreIntegerPosition(index2);

  PVector gridPos1 = pixelpos(intGridPos1.x, intGridPos1.y);
  PVector gridPos2 = pixelpos(intGridPos2.x, intGridPos2.y);

  PVector res = gridPos1.copy().lerp(gridPos2, gridPosLerp);
  return res;
}

PShader voronoiShader; // shader for voronoi cells drawing
PVector[] voronoiPoints;

// Prepare float arrays to pass to the shader
float[] pointArrayX = new float[numberOfPoints];
float[] pointArrayY = new float[numberOfPoints];

void setup() {
  size(600, 600, P2D);
  result = new int[width*height][3];
  smooth(8);

  precomputeMoore(); // for minor/unnecessary optimization, Moore curve positions are computed only once (see moore.pde)

  voronoiShader = loadShader("voronoi.frag");

  voronoiPoints = new PVector[numberOfPoints];
}

void draw_() {
  background(0);

  push();

  for (int i = 0; i < numberOfPoints; i++) {
    // replacement technique (https://bleuje.com/tutorial4/)
    float p = (i+t)/numberOfPoints;
    voronoiPoints[i] = moorePosition(p * numberOfVertices);
  }

  // Fill the point coordinates data for shader
  for (int i = 0; i < numberOfPoints; i++) {
    pointArrayX[i] = voronoiPoints[i].x;
    pointArrayY[i] = voronoiPoints[i].y;
  }

  // Pass the array to the shader as a uniform
  voronoiShader.set("pointsX", pointArrayX);
  voronoiShader.set("pointsY", pointArrayY);
  voronoiShader.set("numberOfPoints", numberOfPoints);
  voronoiShader.set("resolution", float(width), float(height));

  // Apply the shader and draw the full screen quad with voronoi cells drawing
  shader(voronoiShader);
  rectMode(NORMAL);
  rect(0, 0, width, height); // Drawing a rectangle that covers the entire canvas
  resetShader(); // go back to normal Processing drawing mode

  // drawing points dots
  fill(0);
  stroke(255);
  strokeWeight(1.8);
  for (int i = 0; i < numberOfPoints; i++) {
    circle(voronoiPoints[i].x, (height-voronoiPoints[i].y), 6);
    // (height mirror for consistency between processing drawing and shader drawing)
  }

  pop();
}


/* License:
 *
 * Copyright (c) 2024 Etienne Jacob
 *
 * All rights reserved.
 *
 * This Processing code after the template and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
