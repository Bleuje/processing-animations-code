## Spiral wave

![spiral wave gif](https://bleuje.com/gifset/2021/2021_9_starryheightspiral.gif)

## [code](https://github.com/Bleuje/processing-animations-code/blob/main/code/spiralwave/spiralwave.pde)

### comments

(space to separate text from distracting gif)

.

.

.

.

.

.

.

.

.

.

.

.



For the surface shape, we have a function that gives the 3D position by basically getting the height in function of position on 2D plane. This height is computed with a delay that's the distance to center + the angle to this center (obtained with atan2 function).

A black mesh is drawn by drawing a lot of tiny triangles on the surface.

Some particles with random parameters/positions are drawn on the surface, moving outwards (simply moving in lines in the 2D parameters input of the surface). The [replacement technique](https://bleuje.com/tutorial4/) is used, and its parameters make them move at different speed compared to the mesh wave.

### more information and links

Year: 2021

On bleuje site: https://bleuje.com/gifanimationsite/single/spiralwave/

On social media:
 - tumblr: https://necessary-disorder.tumblr.com/post/651898885464326144
 - twitter: https://twitter.com/etiennejcb/status/1470031412711641094
