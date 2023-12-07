## Radial collapse

![radial collapse gif](https://bleuje.com/gifset/2020/2020_4_radialcollapse.gif)

## [code](https://github.com/Bleuje/processing-animations-code/blob/main/code/radialcollapse/radialcollapse.pde)

### comments

We have a set of block instances, 3D array because of different angle, radius position and height. There are a lot more blocks drawn than the number of instances, because of replacement technique (the radius position of the blocks change).

The fall of the blocks is controlled by formulas for the delay/offset of the falls. This formula mostly uses noise based on angle, and block height.

This is a fractal zoom on the radius. The ratio of the fractal zoom 0.8, which means that during the time of one loop, the blocks become smaller and closer to center by a factor 0.8.

The most technical thing in the code, in my opinion, is to define the radius to draw each block in function of parameter p (here p increases by 1 during a loop). The block is drawn using/between these 2 radius:

- r1 = pow(RATIO,p)\*pow(1/RATIO,1.0\*i/N)*R;
- r2 = pow(RATIO,p)\*pow(1/RATIO,1.0\*(i+1)/N)*R;

Where i is the "radius index" of the block (0, 1 or 2), and N the number of radius indices (3). You can check that when p increases by 1, r1, r2 and r2-r1 are multiplied by RATIO=0.8. pow(1/RATIO,1.0*i/N) is about changing the radius depending on radius index i.

Now that we can draw the evolution of a block with parameter p, we can use the [replacement technique (with 3D grid)](https://bleuje.com/tutorial5/) to fill everything and have a perfect loop.

### more information and links

Year: 2020

On bleuje site: https://bleuje.com/gifanimationsite/single/radialcollapse/

On social media:
 - tumblr: https://necessary-disorder.tumblr.com/post/190213558568
 - twitter: (TODO: find link)
