#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec2 resolution;
uniform int numberOfPoints;
uniform float pointsX[16*16];
uniform float pointsY[16*16];

float map(float x,float a,float b,float c,float d)
{
    return c + (x-a)*(d-c)/(b-a);
}

int curveSize = 16;

float pixelMap(float floatIndex)
{
  float w = resolution.x;
  float margin = w/curveSize/2;
  return map(floatIndex, 0, curveSize-1, margin, w-margin);
}

// positions of some points on the 4 sides of the image
// distance to these points is useful to improve the design on the borders
vec2 getBorderPoint(int i)
{
    int side = i%4;
    int localIndex = i/4;

    if(side==0) return vec2(pixelMap(-1),pixelMap(localIndex));
    if(side==1) return vec2(pixelMap(curveSize),pixelMap(localIndex));
    if(side==2) return vec2(pixelMap(localIndex),pixelMap(-1));
    if(side==3) return vec2(pixelMap(localIndex),pixelMap(curveSize));

    return vec2(0,0); // not reached
}

void main() {
  vec2 uv = gl_FragCoord.xy;
  // The point of this fragment shader is to draw voronoi cells

  // Using an algorithm for exact distance to voronoi edges,
  // this algorithm comes from Inigo Quiez: https://iquilezles.org/articles/voronoilines/
  // and see also https://www.shadertoy.com/view/ldl3W8

  float minDist = 10000.0;
  vec2 vToClosestPoint;

  for (int i = 0; i < numberOfPoints; i++) {
    vec2 point = vec2(pointsX[i], pointsY[i]);
    float dist = distance(uv, point);

    if (dist < minDist) {
      vToClosestPoint = point - uv;
      minDist = dist;
    } 
  }

  minDist = 10000.0;
  for (int i = 0; i < numberOfPoints; i++) {
    vec2 point = vec2(pointsX[i], pointsY[i]);
    float dist = distance(uv, point);
    
    vec2 vToPoint = point - uv;
    if( dot(vToClosestPoint-vToPoint,vToClosestPoint-vToPoint)>1.0 )
        minDist = min( minDist, dot( 0.5*(vToClosestPoint+vToPoint), normalize(vToPoint-vToClosestPoint) ) );
  }

  // now something specific to this animation:
  // also using distance to "border points" for nicer design on the borders of the image
  int numberOfBorderPoints = curveSize*4;
  for (int i = 0; i < numberOfBorderPoints; i++) {
    vec2 point = getBorderPoint(i);
    float dist = distance(uv, point);
    
    vec2 vToPoint = point - uv;
    if( dot(vToClosestPoint-vToPoint,vToClosestPoint-vToPoint)>1.0 )
        minDist = min( minDist, dot( 0.5*(vToClosestPoint+vToPoint), normalize(vToPoint-vToClosestPoint) ) );
  }

  
  float stripes = 0.47*min(abs(minDist-4),abs(minDist-10)); // function of shape \/\/, for 2 stripes
  float brightness = smoothstep(0.7,0.3,stripes);
  vec3 color = vec3(brightness);

  gl_FragColor = vec4(color, 1.0);
}

