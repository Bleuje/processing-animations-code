## Sierpinski triangle loop

![Sierpinski triangle loop gif](https://bleuje.com/gifset/other/sierpinskiloop.gif)

## [code](https://github.com/Bleuje/processing-animations-code/blob/main/code/sierpinskiloop/sierpinskiloop.pde) / [simpler version code](https://github.com/Bleuje/processing-animations-code/blob/main/code/sierpinskiloop_simple/sierpinskiloop_simple.pde)

### comments

First there is a function drawFractal to draw a [Sierpinski triangle fractal](https://en.wikipedia.org/wiki/Sierpi%C5%84ski_triangle). This is done by recursion: to draw the fractal into a triangle, draw the triangle, use the middles of its 3 segments to draw the fractals inside it recusively. Stop after a max number ("depth") of iterations.

A technical detail is that the stroke weight of the drawn triangles decreases with iteration and a time parameter p. This time parameter is because of the fractals getting smaller and reaching a new depth after the animation movements. That's what this piece of code is doing: float sw = map(iterationsIndex+p,0,DEPTH,SWMAX,0); strokeWeight(sw); 

Then there is a drawThing function to do one example of movement shown in the animation, by drawing 3 fractals, using interpolation towards middles of the segments of the main triangle. There is a time parameter p, used for both interpolation doing the movement, and the calls to draw fractals (there p is used to control stroke weight and have a perfect loop as mentioned before).

The movement coded in drawThing is reused 3 times with different rotation during the animation. If t is the time of the animation in [0,1], we can get the parameter p of drawThing for a single movement with (3\*t)%1. An [easing function](https://patakk.tumblr.com/post/88602945835/heres-a-simple-function-you-can-use-for-easing) is used for smooth changes.

A "chromatic aberration" effect is used. It's about having a delay between the red, green and blue color components. So this is drawn 3 times in different colors with blendMode(ADD) and different time delays.

The thing is also drawn many times with a for loop and delays to have a quite subtle trail effect.



Here is the 2017 version, without trail and chromatic aberration, that probably looks better, actually:

![Sierpinski triangle loop gif, 2017 version](https://bleuje.com/gifset/2017/2017_7_pinnedsierpinski.gif)

### more information and links

Year: 2017, revised in 2021

On bleuje site: https://bleuje.com/gifanimationsite/single/sierpinskiloop/

On social media:
 - tumblr: https://necessary-disorder.tumblr.com/post/157349897888
 - twitter: https://twitter.com/etiennejcb/status/1367173073250758661
