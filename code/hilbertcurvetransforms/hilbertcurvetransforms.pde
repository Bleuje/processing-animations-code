// Processing code by Etienne JACOB
// motion blur template by beesandbombs, explanation/article: https://bleuje.com/tutorial6/
// CC BY-SA 3.0 license because it's using code from Wikipedia
// View the rendered result at: https://bleuje.com/gifanimationsite/single/hilbertcurvetransforms/

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
int numFrames = 275;        
float shutterAngle = .6;

boolean recording = false; // set to false for time with mouse position, set to true to render frames

// Hilbert curve algo from wikipedia in 2 function below (https://en.wikipedia.org/wiki/Hilbert_curve)
// I haven't tried to understand it yet, but it's fast and quite easy to use

//convert d (it's an index of a vertex on the curve's path) to (i,j) position
// n is the number of vertices, a power of 4 : pow(4,j) where j is the order/level of the curve
PVector d2xy(int n, int d) {
    int rx, ry, s, t=d;
    float x,y;
    x = 0;
    y = 0;
    for (s=1; s<n; s*=2) {
        rx = 1 & (t/2);
        ry = 1 & (t ^ rx);
        PVector res = rot(s, new PVector(x,y), rx, ry);
        x = res.x;
        y = res.y;
        x += s * rx;
        y += s * ry;
        t /= 4;
    }
    
    return new PVector(x,y);
}

//rotate/flip a quadrant appropriately, used in previous function
PVector rot(int n, PVector input, int rx, int ry) {
  float x = input.x;
  float y = input.y;
    if (ry == 0) {
        if (rx == 1) {
            x = n-1 - x;
            y = n-1 - y;
        }

        //Swap x and y
        float t  = x;
        x = y;
        y = t;
    }
    return new PVector(x,y);
}



int numberOfLevels = 6; // number of levels/orders, it's called order in the wikipedia article
int n = (int)pow(4,numberOfLevels); // number of Points/vertices we'll use to draw the curve (this is constant)

class Point
{
  int i;
  
  PVector [] positions = new PVector[numberOfLevels]; // position of point at each level
  
  Point(int i_)
  {
    i = i_;
    
    // finding the pixel position of the point at each level...
    for(int level=1;level<=numberOfLevels;level++)
    {
      int n2 = (int)pow(4,level); // number of vertices of the currentLevel
      float floatIndex = map(i,0,n-1,0,n2-1)*0.999999; // mapping the index (in last level), to the size of smaller level, 0.99999 to avoid reaching the last index and have invalid index later with floor(floatIndex+1)
      // "floatIndex" because it has index range, but isn't an integer
      
      // We are between those two vertices of the curve and will interpolate between them later
      PVector v1 = d2xy(n2,floor(floatIndex));
      PVector v2 = d2xy(n2,floor(floatIndex+1));
      // integer positions so far
      
      float interp = floatIndex - floor(floatIndex); // fractional part, for lerping between v1 and v2 (current level vertices)
      
      // conversion to position in pixels...
      float f = 0.77;
      float numberOfVerticesInARow = pow(2,level); // sqrt(n2)
      float x1 = map(v1.x + 0.5,0,numberOfVerticesInARow,-f*width/2,f*width/2);
      float y1 = map(v1.y + 0.5,0,numberOfVerticesInARow,-f*height/2,f*height/2);
      float x2 = map(v2.x + 0.5,0,numberOfVerticesInARow,-f*width/2,f*width/2);
      float y2 = map(v2.y + 0.5,0,numberOfVerticesInARow,-f*height/2,f*height/2);
      
      positions[level-1] = new PVector(lerp(x1,x2,interp),lerp(y1,y2,interp)); // position found with the interpolation
      
      // mirror fix at every other level that's necessary with the wikipedia formulas, apparently: (x <-> y swap)
      if(level%2==0)  positions[level-1] = new PVector(positions[level-1].y,positions[level-1].x); 
    }
  }
}

Point [] array = new Point[n];

// go from v1 to v2 with rotation around their middle
PVector rotater(PVector v1,PVector v2,float p,boolean orientation) // p is the progress in this interpolation, in [0,1]
{
  PVector middle = v1.copy().add(v2).mult(0.5);
  PVector middleToV1 = v1.copy().sub(middle);
  
  float angle = atan2(middleToV1.y,middleToV1.x);
  float o = (orientation?-1:1);
  float r = middleToV1.mag();
  
  return new PVector(middle.x+r*cos(angle+o*PI*p),middle.y+r*sin(angle+o*PI*p));
}

// easing function taken from https://easings.net/#easeOutElastic
float easeOutElastic(float x)
{
  float c4 = (2*PI)/3;
  if(x<=0) return 0;
  if(x>=1) return 1;
  return pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
}

void drawCurve(float p) // p (in [0,1)) will simply be the time t
{
  p = (p+12345-0.05)%1; // keep p in [0,1[, classic 12345 to make sure it's positive before modulo
   
  p = constrain(map(p,0,0.88,0,1),0,1); // transform p to do nothing for some time
  
  stroke(255);
  strokeWeight(1.4);
  noFill();
  
  beginShape();
  for(int i=0;i<n;i++)
  {
    PVector deepPos = array[i].positions[numberOfLevels-1]; // position on last hilbert curve
    
    float delay = 0.001*deepPos.mag()*sin(PI*p); // using this final position as delay, and not the current position
    // (it creates this weird effect during the first half)
    // sin(PI*p) to use this delay more and more at mid-time (try it without to see the effect?)
    
    float pp = 1-pow(1-p,1.5); // some easing on p
    
    float delayedP = (12345+pp-delay)%1; // 12345 to make sure it's positive before modulo :)
    
    float finishedLastCurveTime = 0.57; // fraction of time to do all transformations except the final one
    // (a lot more time is used to complete the last one=
    
    float floatIndex; // will have level index range but isn't an integer
    if(delayedP<finishedLastCurveTime)
      floatIndex = map(delayedP,0,finishedLastCurveTime,0,numberOfLevels-1);
    else 
      floatIndex = map(delayedP,finishedLastCurveTime,1.0,numberOfLevels-1,numberOfLevels);
    
    int levelIndex1 = floor(floatIndex);
    int levelIndex2 = (levelIndex1+1)%numberOfLevels; // modulo numberOfLevels is important to get from level index numberOfLevels-1 to 0 in last transformation
    float frac = floatIndex - levelIndex1; // fractional part
    
    // we must go from v1 to v2 with some easing/path
    PVector v1 = array[i].positions[levelIndex1];
    PVector v2 = array[i].positions[levelIndex2];
    
    float easing;
    if(levelIndex1==numberOfLevels-1) // special elastic easing only for last transformation
    {
      float aux = constrain(map(frac,0.25,1,0,1),0,1); // transformation to stop a bit before moving
      easing = easeOutElastic(pow(aux,2.2));
    }
    else
      easing = ease(frac,2.2);
    
    PVector v = rotater(v1,v2,easing,levelIndex1%2==0); // go from v1 to v2 with rotation around their middle
    
    vertex(v.x,v.y);
  }
  endShape();
}

void setup(){
  size(600,600,P3D);
  result = new int[width*height][3];
  
  for(int i=0;i<n;i++)
  {
    array[i] = new Point(i);
  }
  
  smooth(8);
}


void draw_(){
  background(0);
  push();
  translate(width/2,height/2);
  
  rotate(-HALF_PI);

  drawCurve(t);

  pop();
}
