// Processing code by Etienne Jacob
// motion blur template by beesandbombs
// See the license information at the end of this file.
// View the rendered result at: https://bleuje.com/gifanimationsite/single/toruscurve/

// slow to render/show
// the distortion effect makes it a lot more dificult to understand completely
// unfinished commenting

int[][] result;
float t, c;

float c01(float x)
{
  return constrain(x,0,1);
}

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
      t %= 1;
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
    
    if (frameCount<=numFrames)
    {
      saveFrame("fr###.gif");
      println(frameCount,"/",numFrames);
    }
    
    if (frameCount==numFrames)
      stop();
  }
}


// end of template
//////////////////////////////////////////////////////////////////////////////

int samplesPerFrame = 6;
int numFrames = 100;        
float shutterAngle = .65;

boolean recording = false;

// class with a coordinates system
// it contains a position and a basis
// also has a show function to debug with RGB vectors of the basis
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

    void showVectors()
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

// IDEA : the curve is on a torus (which has two angles in its parametrization)
// without moving, it does only one full turn with one angle, and with the other it does a lot f turns
// on that first angle there is an added angle increasing with time to do some kind of replacement technique

// Torus size parmaters
float R1 = 130;
float R2 = 70;

int turns = 8; // number of spiral turns with the angle with more turns

// Torus surface equation
PVector torusSurface(float alpha,float theta)
{
  float z = 2.15*(R2)*sin(alpha); // 2.15 factor for streching on z axis
  float x = (R1+(R2)*cos(alpha))*cos(theta);
  float y = (R1+(R2)*cos(alpha))*sin(theta);
  return new PVector(x,y,z);
}

// defining the main curve equation
// but also getting a continuous basis
Coordinates curve(float p)
{
  float alpha = TWO_PI*(p-t/turns); // change with t for some kind of replacement technique
  float theta = TWO_PI*p*turns;
  PVector pos = torusSurface(alpha,theta); // this is already the position on the curve
  
  // rest of this function is to get a smooth looping coordinates basis change
  PVector pos2 = torusSurface(alpha+0.1,theta); // something useful : getting another point by changing a bit one of the angles on torus
  PVector diff = pos2.copy().sub(pos); // vector from pos to pos2
  PVector v2 = diff.normalize(); // we already have one of the vectors of the basis with this
  
  // now we go a bit further than pos along the curve, to get another vector
  float alpha2 = TWO_PI*((p+0.0001)-t/turns);
  float theta2 = TWO_PI*(p+0.0001)*turns;
  PVector pos3 = torusSurface(alpha2,theta2); // we're now here
  PVector diff2 = pos3.copy().sub(pos); // converting position to a vector from pos
  PVector v1 = diff2.normalize(); // so this is what we get
  
  PVector v3 = v1.copy().cross(v2); // getting a vectot orthogonal to the plane formed by v1 and v2, with cross product
  
  Coordinates coords = new Coordinates(pos,v1,v2,v3);
  return coords;
}

// distortion effect on the curve parametrization
// this is super tricky and really hard to get back into understanding it
// the surface equation defined next includes this distortion
PVector easedParam(float p)
{
  float dontChange = pow(c01(sin(PI*((p-t/turns+1)%1))),2.5); // parameter to have much less distortione in the area in the center
  
  float F = 7*turns+turns/2;
  float q = (F*p+0.5*t); // map p to a larger range (a range on indices), and have it increase by half an index with a loop duration
  
  int index = floor(q);
  float frc = q-index; // fractional part of q
  float frc2 = lerp(frc,ease(frc,lerp(4.7,1.2,dontChange)),0.65); // less easing when dontChange increases, inside a lerp to ahve a mix with no easing
  frc = lerp(frc,frc2,0.43); // another mix to control the easing curve
  float q2 = index+frc; // modfied q with easing
  
  return new PVector((q2-0.5*t)/F,frc); // first argument is the distorted p, the second one frc in [0,1] is returned to remember where we are comapred to distortion
  // (q2-0.5*t)/F : the previous + 0.5*t has useful to translate the fractional part of q, so translate the easing
  // now we remove that 0.5*t to come back to a p "at the same location"
  // division by F to come back to the range of p
}

// surface around the main curve
// we're at p on the curve
// theta is the angle in the circle around the curve
// d is a parameter to increase the radius, useful for code factorization at some point
PVector curveSurface(float p,float theta,float d) 
{
  p = easedParam(p).x;
  Coordinates coords = curve(p); // we will use the basis at p
  float r = 12+d; // radius of circle
  PVector pos = coords.position;
  PVector v = pos.copy().add(coords.u2.copy().mult(r*cos(theta))).add(coords.u3.copy().mult(r*sin(theta)));
  return v;
}

// mesh quality parameters
int mMesh = 90*turns;
int mTheta = 13;

// draw black mesh around the main curve (lots of triangles with TRIANGLE_STRIP)
// using previous curveSurface function with d=0
void drawMesh()
{
  stroke(100);
  strokeWeight(1.0);
  noStroke();
  fill(0);
  
  for(int i=0;i<mMesh;i++)
  {
    float p1 = 1.0*i/mMesh;
    float p2 = 1.0*(i+1)/mMesh;
    int mTheta2 = 2*mTheta;
    beginShape(TRIANGLE_STRIP);
    for(int j=0;j<=mTheta2;j++)
    {
      float theta = 1.0*j/mTheta2*TWO_PI;
      PVector v1 = curveSurface(p1,theta,0);
      PVector v2 = curveSurface(p2,theta,0);
      vertex(v1.x,v1.y,v1.z);
      vertex(v2.x,v2.y,v2.z);
    }
    endShape(CLOSE);
  }
}

// drawing quite evenly distributed dots on curve with small white spheres
void drawDots()
{
  stroke(100);
  strokeWeight(1.0);
  fill(0);
  
  int numberOfCircles = mMesh*2;
  
  for(int i=0;i<numberOfCircles;i++)
  {
    float p = 1.0*i/numberOfCircles;
    for(int j=0;j<=mTheta;j++)
    {
      float theta = 1.0*(j+(i%2==0?0:0.5))/mTheta*TWO_PI-4*t*TWO_PI/mTheta; // offset every other circle for better distribution, looping rotation with time
      float p2 = (p+6.0*t/mMesh); // some forward progression on the curve with time
      PVector v = curveSurface(p2,theta,1.3); // position 1.3 pixels away from the black mesh
      
      // computing sphere size...
      float es = easedParam(p2).y; // where we are compared to distortion, in [0,1]
      float dontChange = pow(c01(sin(PI*((p2-t/turns+1)%1))),3.3); // parameter to have much less sphere size change in the area in the center
      float szf = map(pow(c01(sin(PI*es)),8.0),0,1,0.9,2.9); // size factor, larger sphere for es closer to 0.5, with sin(PI*es)
      szf = lerp(szf,1.0,0.95*dontChange); // just go towards 1.0 size factor when don't change increases
      
      push();
      translate(v.x,v.y,v.z);
      
      sphereDetail(5);
      fill(255);
      noStroke();
      
      sphere(1.0*szf);
      pop();
    }
  }
}

// moving particles/trails around distortion
void drawParticles()
{
  stroke(100);
  strokeWeight(1.0);
  fill(0);
  
  int mParts = 7*turns+4; // number of distortions, or the number of groups
  
  float mParticles = 4; // number of trails per group
  
  int nTrail = 40; // number of particles on one trail
  
  for(int k=0;k<nTrail;k++)
  {
    float pk = map(k,0,nTrail,1,0);
    for(int i=0;i<mParts;i++)
    {
      float p = 1.0*i/mParts;
      for(int j=0;j<mParticles;j++)
      {
        float theta = 1.0*(j+(i%2==0?0:0.5))/mParticles*TWO_PI-5*t*TWO_PI/mParticles-4.7*pk;
        float p2 = p-0.5*t/mParts-0.5/mParts+0.007*(0.6-pk);
        PVector v = curveSurface(p2,theta,7.0); // d=7.0 pixels away from surface
        
        push();
        translate(v.x,v.y,v.z);
        
        sphereDetail(6);
        fill(255);
        noStroke();
        
        sphere(2.0*pk);
        pop();
      }
    }
  }
}

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  smooth(8);
}


void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  rotateX(HALF_PI);
  
  drawMesh();
  
  drawDots();
  
  drawParticles();
  
  // for debugging :
  //Coordinates coords = curve(c);
  //coords.showVectors();

  pop();
}


/* License:
 *
 * Copyright (c) 2023 Etienne Jacob
 *
 * All rights reserved.
 *
 * This code and the related animations are the property of the
 * copyright holder. Any reproduction, distribution, or use of this material,
 * in whole or in part, without the express written permission of the copyright
 * holder is strictly prohibited.
 */
