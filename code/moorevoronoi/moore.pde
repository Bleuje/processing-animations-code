int curveSize = 16; // must be a power of 2
int numberOfVertices = curveSize * curveSize;

float W = 600; // = width in 600x600, it's often useful to avoid Processing's width variable, to be able to change easily the resolution with the scale function
float margin = 0.5*W/curveSize;

// Hilbert curve algo from Wikipedia in functions d2xy_hilbert and rot below (https://en.wikipedia.org/wiki/Hilbert_curve)

// convert d (it's an index of a vertex on the curve's path) to (i,j) position
// n * n is the number of vertices, a power of 4 : pow(4,j) where j is the order/level of the curve
PVector d2xy_hilbert(int n, int d) {
  int rx, ry, s, t=d;
  float x, y;
  x = 0;
  y = 0;
  for (s=1; s<n; s*=2) {
    rx = 1 & (t/2);
    ry = 1 & (t ^ rx);
    PVector res = rot(s, new PVector(x, y), rx, ry);
    x = res.x;
    y = res.y;
    x += s * rx;
    y += s * ry;
    t /= 4;
  }

  return new PVector(x, y);
}

//rotate/flip a quadrant appropriately
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
  return new PVector(x, y);
}

// Moore curve (https://en.wikipedia.org/wiki/Moore_curve)
// convert d to (x,y), using 4 Hilbert curves.
PVector d2xy_moore(int n1, int d) {
  int n = n1/2; // n for 2 times smaller Hilbert curve than this Moore curve
  int m = n*n;

  d = (d+4*m)%(4*m); // just making sure d is in [0,4*m[

  PVector aux = d2xy_hilbert(n, d%m); // position on local Hilbert curve

  if (d<m) return new PVector(aux.x, n-aux.y-1);
  else if (d<2*m) return new PVector(aux.x+n, n-aux.y-1);
  else if (d<3*m) return new PVector(n-aux.x+n-1, aux.y+n);
  else if (d<4*m) return new PVector(n-aux.x-1, aux.y+n);

  return new PVector(0, 0); // we should never reach this case
}

PVector [] precomputedMoore = new PVector[numberOfVertices];

void precomputeMoore() {
  for (int i=0; i<numberOfVertices; i++) {
    precomputedMoore[i] = d2xy_moore(curveSize, i);
  }
}

PVector getMooreIntegerPosition(int i) {
  i = ((i%numberOfVertices)+numberOfVertices)%numberOfVertices; // loop the index
  return precomputedMoore[i];
}

float pixelPosMap(float fint) {
  return map(fint, 0, curveSize-1, margin, W-margin);
}

// ix and iy are integer positions of the grid
PVector pixelpos(float ix, float iy) {

  float x = pixelPosMap(ix);
  float y = pixelPosMap(iy);
  return new PVector(x, y);
}