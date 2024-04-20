## Fluid sphere obstacle

![fluid sphere obstacle gif](https://bleuje.com/gifset/2017/2017_22_sphereagainsflow_v2.gif)

## [code](https://github.com/Bleuje/processing-animations-code/blob/main/code/fluidsphereobstacle/fluidsphereobstacle.pde)

### comments

It's using a simulation of particles following a flow field.

The flow field is defined by the sum of:
- a constant speed field
- a repulsive field (might be the most technical part of the code)
- some perlin noise

Once the particle paths are computed, [replacement technique](https://bleuje.com/tutorial4/) is used to show particles following them. It's also using interpolation between computed positions of the simulation [(tutorial)](https://bleuje.com/tutorial7/).

A black sphere is then simply drawn, its position and size have been adjusted experimentally.

### more information and links

Year: 2017

On bleuje site: https://bleuje.com/gifanimationsite/single/fluidsphereobstacle/

On social media:
 - tumblr: https://necessary-disorder.tumblr.com/post/164452980553
 - twitter: https://twitter.com/etiennejcb/status/1439309996471341059
