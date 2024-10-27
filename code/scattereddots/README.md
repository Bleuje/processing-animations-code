## Scattered dots

![scattered dots gif](https://bleuje.com/gifset/2018/2018_26_popularlerpdotpath.gif)

## [code](https://github.com/Bleuje/processing-animations-code/blob/main/code/scattereddots/scattereddots.pde)

#### some used techniques

replacement technique, simulation

### other comments

This animation is simple but has had a lot of success on tumblr.

It's using particles following a single path with [replacement technique](https://bleuje.com/tutorial4/).

First the positions of the path are computed at setup, using jumps of random length, in 8 different directions. There are checks to go in opposite direction when the jump crosses a margin.

From this list, the position at parameter p in [0,1] is found using interpolation between positions of the list [(tutorial)](https://bleuje.com/tutorial7/). The interpolation uses [an easing function](https://patakk.tumblr.com/post/88602945835/heres-a-simple-function-you-can-use-for-easing), which makes the dots stop and move smoothly. Once we've got this parametrization of the path, the [replacement technique](https://bleuje.com/tutorial4/) is used, with less dots on the path than its number of jumps.

Similarly to position, there is a list of sizes of dot, and interpolation between these sizes.

### links

On bleuje site: https://bleuje.com/gifanimationsite/single/scattereddots/

On social media:
 - tumblr: https://necessary-disorder.tumblr.com/post/175311166118
 - twitter: (TODO: find link)
