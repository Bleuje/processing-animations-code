# Processing animations source code list

Here are the links to the source codes of some of my animations. For more context and insights about this project, please read the text below.


| Code link | Result | Year | Difficulty rating | Some used techniques |
|-------------|--------|------|-------------------|--------------------|
| [**hilbert curve transforms**](https://github.com/Bleuje/processing-animations-code/blob/main/code/hilbertcurvetransforms/hilbertcurvetransforms.pde) | [view](https://bleuje.com/gifanimationsite/single/hilbertcurvetransforms/) | 2022 | ● ● ● (6) | easing, hilbert curve |
| [**sphere wave**](https://github.com/Bleuje/processing-animations-code/blob/main/code/spherewave/spherewave.pde) | [view](https://bleuje.com/gifanimationsite/single/spherewave/) | 2022 | ● ● ● (6) | vector maths, easing |
| [**Sierpinski triangle loop**](https://github.com/Bleuje/processing-animations-code/blob/main/code/sierpinskiloop/sierpinskiloop.pde) | [view](https://twitter.com/etiennejcb/status/1367173073250758661) | 2017/2021 | ● ● (4) | recursion, chromatic abberation |
| [**radial collapse**](https://github.com/Bleuje/processing-animations-code/blob/main/code/radialcollapse/radialcollapse.pde) | [view](https://bleuje.com/gifanimationsite/single/radialcollapse/) | 2020 | ● ● ◐ (5) | fractal zoom, replacement technique, noise |
| [**2D fractal sliding squares** **\***](https://github.com/Bleuje/processing-animations-code/blob/main/code/fractalsliding2d/fractalsliding2d.pde) | [view](https://bleuje.com/gifanimationsite/single/2dfractalslidingsquares/) | 2023 | ● ● ● (6) | recursion, fractal zoom, tree structure |
| [**torus curve**](https://github.com/Bleuje/processing-animations-code/blob/main/code/toruscurve/toruscurve.pde) | [view](https://bleuje.com/gifanimationsite/single/toruscurve/) | 2023 | ● ● ● ● (8) | 3D geometry, mesh |
| [**fluid sphere obstacle**](https://github.com/Bleuje/processing-animations-code/blob/main/code/fluidsphereobstacle/fluidsphereobstacle.pde) | [view](https://bleuje.com/gifanimationsite/single/fluidsphereobstacle/) | 2017 | ● ● (4) | simulation, replacement technique |
| [**spiral magic**](https://github.com/Bleuje/processing-animations-code/blob/main/code/spiralmagic/spiralmagic.pde) | [view](https://bleuje.com/gifanimationsite/single/spiralmagic/) | 2021 | ● ● ● (6) | camera projection trick, spiral |
| [**two levels sliding**](https://github.com/Bleuje/processing-animations-code/blob/main/code/twolevelssliding/twolevelssliding.pde) | [view](https://bleuje.com/gifanimationsite/single/twolevelssliding/) | 2021 | ● ● ● (6) | replacement technique, simulation |
| [**sphere impacts**](https://github.com/Bleuje/processing-animations-code/blob/main/code/sphereimpacts/sphereimpacts.pde) | [view](https://bleuje.com/gifanimationsite/single/sphereimpacts/) | 2021 | ● ● ◐ (5) | particles effects, 3D geometry |
| [**spiral wave**](https://github.com/Bleuje/processing-animations-code/blob/main/code/spiralwave/spiralwave.pde) | [view](https://bleuje.com/gifanimationsite/single/spiralwave/) | 2021 | ● ● (4) | replacement technique, mesh, spiral wave |
| [**permutation patterns propagation**](https://github.com/Bleuje/processing-animations-code/blob/main/code/permutationpatternspropagation/permutationpatternspropagation.pde) | [view](https://bleuje.com/gifanimationsite/single/permutationpatternspropagation/) | 2021 | ● ● ● ◐ (7) | simulation, permutation patterns |
| [**sun connections**](https://github.com/Bleuje/processing-animations-code/blob/main/code/sunconnections/sunconnections.pde) | [view](https://bleuje.com/gifanimationsite/single/sunconnections/) | 2018 | ● ● (4) | interpolation with delay, noise loop |
| [**scattered dots**](https://github.com/Bleuje/processing-animations-code/blob/main/code/scattereddots/scattereddots.pde) | [view](https://bleuje.com/gifanimationsite/single/scattereddots/) | 2018 | ● (2) | replacement technique, simulation |

\* Collaboration with Yann Le Gall

Most animations rely a lot on delay/offset techniques (something normal when time is involved :) ). Most of them also use basic object oriented programming.


#### About ratings

Please note that these ratings are highly subjective and are intended to serve as a rough guide for navigating the collection. While it's not ideal, they offer some insight into the complexity of understanding the code.

---

# Motivation and information

During my early months exploring animations with [Processing](https://processing.org/), I stumbled upon the source code of some captivating gifs created by [beesandbombs (Dave)](https://beesandbombs.com/). Although I only examined a fraction of his [code examples](https://gist.github.com/beesandbombs), I made the effort to comprehend them as much as possible. This experience significantly influenced my skills – I discovered new techniques, had some enigmas unraveled, improved my mathematical approach, and improved my workflow. I even adopted Dave's motion blur template.

Over the years, I've shared numerous source codes from my animations. However, I often presented these codes in their raw form, as they appeared once I completed each animation. This approach allowed me to genuinely reveal my work with minimal effort while also showcasing the mathematical concepts behind them. My primary focus was always on the visual outcome, rather than perfecting the code's aesthetics.

With the support and encouragement I've received, I believe that sharing my animation creation process might hold value for others. I do not claim that my code is ideally suited for educational purposes, but I believe that, by refining it, others could potentially gain knowledge and improve their skills from studying my work – similar to my own experience with beesandbombs.

The aim of this project is to compile a selection of animation source codes that I find noteworthy, while enhancing and clarifying them through clearer, commented code. As I continue to add new examples and refine existing ones, this project should be a permanent work in progress. Although the code may have imperfections (e.g., suboptimal variable names or not the simplest possible solutions), I hope it represents a meaningful improvement over my previously shared work.

To better understand the examples, those new to creative coding or looking for additional context might find it helpful to first explore the [**tutorials on my website**](https://bleuje.com/tutorials/). In particular, the "[Replacement Technique](https://bleuje.com/tutorial4/)" and the tutorial about beesandbombs' [motion blur template](https://bleuje.com/tutorial6/) provide context and foundational knowledge. 

I hope that this collection of animation source code might serve as a valuable resource for those interested in delving deeper into the world of Processing-based animations, whether for educational purposes or simply to satisfy their curiosity. I hope that my work could inspire and support others on their creative journeys, just as beesandbombs' work has done for me.

## Acknowledgments and Licensing

This repository includes animations that utilize a [motion blur template](https://bleuje.com/tutorial6/) created by Dave. I have permission from him to use this template in my work.

Please note that while the motion blur template is available for use, the rest of the source code in this repository is generally protected under my copyright, and all rights are reserved. If you wish to use any part of my source code for your own projects or any other purpose, please contact me to obtain permission.
