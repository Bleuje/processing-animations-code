// Processing code by Etienne JACOB
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/spiralssphere/

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

// short one to map an x from [a,b] to [0,1] and constrain
float mp01(float x, float a, float b)
{
  return map(x,a,b,0,1,true);
}

// reversed pow that does some kind of ease out, [0,1] -> [0,1], with a parameter g
float pow_(float p, float g)
{
  return 1-pow(1-p,g);
}

// hyperbolic tangent, maps ]-infinity,+infinity[ to ]-1,1[ 
float tanh(float x)
{
  return (float)Math.tanh(x);
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
      saveFrame("fr###.gif");
      println(frameCount,"/",numFrames);
    }
    
    if (frameCount==numFrames)
      stop();
  }
}

// End of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 6;
int numFrames = 420;        
float shutterAngle = 0.4;

boolean recording = false;


float SphereRadius = 140;

float numberOfSpiralsFactor_0 = 0.025; 
float numberOfSpiralsFactor; // evolving global variable

float currentSphereSpiralPosition; // evolving global variable, in [0,1]
// (represents where we are between the 2 poles)


// Idea / notations :
// We have a theoretical infinite repetition of small spirals on an infinite straight x-axis,
// with each small spiral indexed by an integer k.
// We distort and bound this axis to [-1,1] with the tanh function.
// When we're at a position p in [-1,1] in the distortion,
// we'll have to look for which x (and k) values it corresponds to.
// Later we'll draw this along the 3D sphere curve.

// Saying "small spirals" as opposed to the sphere curve that also looks like a kind of spiral.

// A lot of complicated details were added to get exactly what I wanted to have


// Function to map an index to a position on and x-axis,
// also possibility to shift this position with the parameter xShift
float xFromK(int k,float xShift)
{
  return (k + xShift) * numberOfSpiralsFactor;
}

// inverse function of tanh, used in next function
float tanhInverse(float p)
{
  return 0.5 * (log(1+p)-log(1-p));
}

// We're at a position p in [-1,1] on the plain sphere curve, where -1 and 1 are at sphere poles,
// this function is used to get the index k of the small spiral we're on for this p
// (with the tanh distortion)
int KFromP(float p,float xShift)
{
  float x = tanhInverse(p); // this is the x position on infinite x-axis after reversing the tanh distortion
  int k = floor(x/numberOfSpiralsFactor - xShift); // index k from x
  return k; 
}

// Equations for a full small spiral
// parametrized by q in [0,1]
// there are two cases because two directions from the center of the spiral
PVector smallSpiralPattern(float q,float numberOfTurns,float rad)
{
  if(q<=0.5) // first direction
  {
    float pSpiral = 1.0 - mp01(q, 0, 0.5);
    float theta = sqrt(pSpiral) * numberOfTurns * TAU  -  numberOfTurns * TAU;
    float r = sqrt(pSpiral) * rad;
    
    return new PVector(r*cos(theta),r*sin(theta));
  }
  else // other direction
  {
    float pSpiral = mp01(q, 0.5, 1.0);
    float theta = sqrt(pSpiral) * numberOfTurns * TAU  -  numberOfTurns * TAU  +  PI;
    float r = sqrt(pSpiral) * rad;
    
    return new PVector(r*cos(theta), r*sin(theta));
  }
}

// p in [-1,1] is a position on the sphere curve with -1 and 1 at the two poles
// we look for 2D positions of small spirals along a straight axis,
// putting this on the 3D sphere curve will be done later
PVector spiralPatternFromP(float p,float xShift,float numberOfTurnsFactor)
{
  int k1 = KFromP(p, xShift);
  int k2 = k1 + 1;
  float p1 = tanh(xFromK(k1, xShift));
  float p2 = tanh(xFromK(k2, xShift));
  
  
  
  // effect that has the moving variation of turns every other small spiral...
  float turnsSwitchIntensity = 0.5 * ease(map(t, 0.42, 0.94, 1, 0.6, true), 1.3);
  float everyOtherSpiralTimeOffset = 0.5 * (k1%2);
  float turnsSwitchSpeed = 2.6 * pow(mp01(t, 0.2, 1), 2.6);
  
  float alternatingNumberOfTurnsFactor =
            turnsSwitchIntensity * cos(TAU * (turnsSwitchSpeed + everyOtherSpiralTimeOffset));
  
  float numberOfTurnsFactor2 =  1.15 + alternatingNumberOfTurnsFactor;
  
  
  // propagation of small spiral construction happens here thanks to currentSphereSpiralPosition
  float numberOfTurnsChangeWithP = c01(sin(PI*currentSphereSpiralPosition))*pow_(t, 2.0);
  float delay = (1 - sin(PI*currentSphereSpiralPosition))*0.8;
  float numberOfTurnsPropagationFactor = ease(pow_(mp01(numberOfTurnsChangeWithP - delay, 0, 1.0 - delay), 2.7), 1.3);
  
  // finally :
  float numberOfSmallSpiralTurns = numberOfTurnsFactor * numberOfTurnsFactor2 * numberOfTurnsChangeWithP * numberOfTurnsPropagationFactor;
  
  
  
  float smallSpiralRadius = (p2-p1)/2; // half the distance between the two p we're at
  
  float localSmallSpiralQ = 1.0 - (p-p1)/(p2-p1);  // (parameter with orientation fix with 1.0- : mirrored right/left of small spiral)
  
  PVector v_local = smallSpiralPattern(localSmallSpiralQ,
                                       numberOfSmallSpiralTurns,
                                       smallSpiralRadius);
  
  float middleP = (p1+p2)/2;
  
  PVector v = new PVector(middleP + v_local.x, v_local.y); // v.x is a p in [-1,1], v.y is the current height
  
  return v; 
}

// Rotate a PVector around Y axis
PVector rotY(PVector v,float theta)
{
  float x = v.x*cos(theta) - v.z*sin(theta);
  float z = v.x*sin(theta) + v.z*cos(theta);
  return new PVector(x,v.y,z);
}

// Equations of plain sphere curve
// courtesy of jn3008 / @jn3008 / "Jo"
PVector curvePath(float q,float s) {
    PVector v  = new PVector(0, -1, 0);
    v.rotate(TAU*q);
    v = rotY(v, s*TAU*(2*q < 1? q*2:2-2*q) - s*PI );
    v.mult(SphereRadius);
    return v;
}

// Class that represents a position and a 3D basis at the position,
// used to have a well oriented drawing along the 3D curve
class Coordinates
{
    PVector position;
    PVector u1, u2, u3;

    Coordinates(PVector pos, PVector u1_, PVector u2_, PVector u3_)
    {
        position = pos;
        u1 = u1_.copy().normalize();
        u2 = u2_.copy().normalize();
        u3 = u3_.copy().normalize();
    }

    void showVectors() // for debugging
    {
        push();
        translate(position.x, position.y, position.z);

        float F = 30;

        strokeWeight(5.0);

        stroke(255, 0, 0);
        line(0, 0, 0, u1.x*F, u1.y*F, u1.z*F);
        stroke(0, 255, 0);
        line(0, 0, 0, u2.x*F, u2.y*F, u2.z*F);
        stroke(0, 0, 255);
        line(0, 0, 0, u3.x*F, u3.y*F, u3.z*F);


        pop();
    }
}

// Now we don't want just the position on plain sphere curve
// but also get the smooth turning basis on that curve
// to orient the drawing of small spirals later
Coordinates curveCoordinates(float q,float sphereCurveChangeParameter)
{
  PVector pos = curvePath(q,sphereCurveChangeParameter);
  PVector pos2 = curvePath(q+0.005,sphereCurveChangeParameter);
  PVector diff = pos2.copy().sub(pos);
  PVector v2 = diff.normalize();
  
  PVector pos3 = pos.copy().mult(1.1);
  PVector v1 = (pos3.copy().sub(pos)).normalize();
  
  PVector v3 = v1.copy().cross(v2);
  
  Coordinates coords = new Coordinates(pos,v1,v2,v3);
  return coords;
}

// Function to get 3D positions of the entire 3D curve with small spirals,
// in function of the position parameter fullSphereSpiralParameter in [0,1]  and other parameters.
// Putting the 2D small spirals on the sphere curve.
PVector spiralsCurve(float fullSphereSpiralParameter,float sphereCurveChangeParameter,float numberOfTurnsFactor,float xShift,float heightFactor)
{
  float q;
  PVector v_2D;
  
  if(fullSphereSpiralParameter<=0.5) // first half of the sphere spiral (from one pole to the other one)
  {
    float q0 = mp01(fullSphereSpiralParameter, 0, 0.5);
    
    currentSphereSpiralPosition = q0; // setting the global variable to know where we are between the 2 poles
    
    v_2D = spiralPatternFromP(2*(q0-0.5)*0.999, xShift, numberOfTurnsFactor);
    
    q = map(v_2D.x, -1, 1, 0, 0.5); // mapping the p (v_2D.x) in [-1,1] that we got to the entire sphere curve parameter
  }
  else // second half of the sphere spiral (from one pole to the other one)
  {
    float q0 = mp01(fullSphereSpiralParameter, 0.5, 1.0);
    
    currentSphereSpiralPosition = q0;
    
    v_2D = spiralPatternFromP(2*(q0-0.5)*0.999, xShift, numberOfTurnsFactor);
    
    q = map(v_2D.x, -1, 1, 0.5, 1.0);
  }
  
  Coordinates coords = curveCoordinates(q,sphereCurveChangeParameter); // get position and basis on plain sphere curve at q
  
  float flatEndingFactor = ease(map(t,0.9,0.975,1,0,true), 1.7); // maybe some kind of perfectionnism, it's factor that goes from 1 to zero from t=0.9 to t=0.975
  
  float spiralHeightFactor = 13.5 * heightFactor * v_2D.y * SphereRadius * flatEndingFactor;
  
  PVector local3DPos = coords.u3.copy().mult(spiralHeightFactor);
  
  PVector v_3D = coords.position.copy()
                  .add(local3DPos);
  
  return v_3D;
}

// Without projection on sphere,
// the small spirals would be drawn on a parallel plane to the sphere
PVector projectOnSphere(PVector v)
{
  return v.mult(SphereRadius/v.mag());
}


// Final function to get the 3D position of the final curve,
// in function of the position parameter fullSphereSpiralParameter in [0,1]
// and two other arguments to activate stuff
PVector curveTransformation(float fullSphereSpiralParameter,float mainActivation,float numberOfSmallSpiralsTurnsActivation)
{
  numberOfSpiralsFactor = pow(numberOfSpiralsFactor_0, pow(abs(mainActivation), 0.5));
  
  float sphereCurveChangeParameter = 5 * pow(mainActivation, 2.0);
  
  float numberOfSmallSpiralTurnsFactor = 2 * pow(mp01(numberOfSmallSpiralsTurnsActivation, 0.3, 1.0), 2.0);
  
  float xShift = 13 * pow(t, 2.7) + 0.15 + 40*pow(mp01(t, 0.4, 1), 5.0);
  
  float smallSpiralsHeightFactor = pow(mainActivation, 2.0);
  
  PVector v = spiralsCurve(fullSphereSpiralParameter,
                           sphereCurveChangeParameter,
                           numberOfSmallSpiralTurnsFactor,
                           xShift,
                           smallSpiralsHeightFactor);
                           
  v = projectOnSphere(v);
  
  return v;
}

// useful function to have some stroke weight propagation
float propagatedLightFunction(float x)
{
  return 1.3 * pow(c01(min(6*x, 1-x)), 2.0);
}

void setup()
{
  size(720,720,P3D);
  result = new int[width*height][3];
  smooth(8);
}

void draw_()
{
  float fov = PI/1.8;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), 
              cameraZ/10.0, cameraZ*10.0);
            
  background(0);
  push();
  translate(width/2,height/2);
  
  scale(2.6);
  
  // in second half progressive rotate Z of the entire structure
  rotateZ(1.8 * PI * pow(mp01(t,0.34,1.0), 4.4));
  
  float activate = ease(pow(mp01(t, 0, 0.49), 1.2), 1.8);
  float deactivate = ease(pow(mp01(t, 0.3, 1.0), 3.0), 2.5);
  float mainActivation = activate - deactivate; // parameter to activate most of the structure
  
  float numberOfSmallSpiralsTurnsActivation = mp01(t, 0, 0.39);

  float strokeWeightFactor = (1.2 + 0.6 * pow(1 - c01(sin(PI*t)), 2.0)) * 0.62;
  
  // drawing the whole curve by connecting vertices...
  int numberOfVertices = 45000;
  noFill();
  beginShape();
  for(int i=0;i<numberOfVertices;i++)
  {
    float q = 1.0 * i/numberOfVertices;
    PVector v = curveTransformation(q, mainActivation, numberOfSmallSpiralsTurnsActivation);
    v = projectOnSphere(v);
    
    // stroke color
    stroke(map(modelZ(v.x,v.y,v.z), SphereRadius, -SphereRadius, 300, 190));
    
    // change the stroke weight along small spirals construction/propagation
    float offset = (1-sin(PI*currentSphereSpiralPosition))*0.95;
    float strokeWeightConstructionFactor = 7.3*(0.4*t+0.8)*mp01(t,0.15,0.3)*propagatedLightFunction(3*(mp01(t,0.16,0.68)-offset))*ease(map(t,0.25,0.55,1,0,true),1.3);
    
    // other stroke weight factors
    float depth = 500 - modelZ(v.x,v.y,v.z); // looking for z depth to have smaller stroke weight in the distance
    float depthFactor = 200/depth;
    float sw = strokeWeightFactor
              * (1 + 1.6*strokeWeightConstructionFactor)
              * depthFactor;
    strokeWeight(sw);
    
    vertex(v.x,v.y,v.z);
  }
  endShape(CLOSE);
  
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
