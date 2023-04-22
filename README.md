# Processing animations source code list

Here are the links to the source codes of some of my animations. For more context and insights about this project, please read the text below.


| Code link (gist) | Result | Year | Difficulty rating | Some used concepts |
|-------------|--------|------|-------------------|--------------------|
| [**hilbert curve transforms**](https://gist.github.com/Bleuje/0917441d809d5eccf4ddcfc6a5b787d9) | [view](https://bleuje.com/gifanimationsite/single/hilbertcurvetransforms/) | 2022 | ⭐⭐⭐⭐ | easing, hilbert curve |
| [**sphere wave**](https://gist.github.com/Bleuje/bd3e59266899687c11dbca39f1ffd7ae) | [view](https://bleuje.com/gifanimationsite/single/spherewave/) | 2022 | ⭐⭐⭐⭐ | vector maths, easing |
| [**Sierpinski triangle loop**](https://gist.github.com/Bleuje/1307e4c10898b93a25e159edbef8ea3c) | [view](https://twitter.com/etiennejcb/status/1367173073250758661) | 2017/2021 | ⭐⭐+ | recursion, chromatic abberation |
| [**radial collapse**](https://gist.github.com/Bleuje/3889f5ec12645c5d4ffd24cf7f96282a) | [view](https://bleuje.com/gifanimationsite/single/radialcollapse/) | 2020 | ⭐⭐⭐ | fractal zoom, replacement technique, noise |
| [**2D fractal sliding squares**](https://gist.github.com/Bleuje/5a71f27afedfb7869daf8c81f7a05367) | [view](https://bleuje.com/gifanimationsite/single/2dfractalslidingsquares/) | 2023 | ⭐⭐⭐⭐+ | recursion, fractal zoom, tree structure |
| [**digits spiral**](https://gist.github.com/Bleuje/c80e14b134090e453eefed3ae890a88c) | [view](https://bleuje.com/gifanimationsite/single/digitsspiral/) | 2018 | ⭐⭐ | replacement technique, spiral, noise |
| [**torus curve**](https://gist.github.com/Bleuje/4239c7eabb4781823bc0e085fac005e5) | [view](https://bleuje.com/gifanimationsite/single/toruscurve/) | 2023 | ⭐⭐⭐⭐⭐+ | 3D geometry, mesh |
| [**fluid sphere obstacle**](https://gist.github.com/Bleuje/a2e9beef7476cd4854da61d48b1f5dac) | [view](https://bleuje.com/gifanimationsite/single/fluidsphereobstacle/) | 2017 | ⭐⭐+ | simulation, replacement technique |
| [**spiral magic**](https://gist.github.com/Bleuje/f5cebe99210bb51c4d4b27e9f740f498) | [view](https://bleuje.com/gifanimationsite/single/spiralmagic/) | 2021 | ⭐⭐⭐⭐ | camera projection trick, spiral |
| [**two levels sliding**](https://gist.github.com/Bleuje/637a28417e5014c653c038a502098bb8) | [view](https://bleuje.com/gifanimationsite/single/twolevelssliding/) | 2021 | ⭐⭐⭐⭐ | replacement technique, simulation |
| [**sphere impacts**](https://gist.github.com/Bleuje/dffc57d356d754aa6efe0e06205aa01d) | [view](https://bleuje.com/gifanimationsite/single/sphereimpacts/) | 2021 | ⭐⭐⭐ | particles effects, 3D geometry |
| [**spiral wave**](https://gist.github.com/Bleuje/82750bb2aba5470f17394dd58e96dd89) | [view](https://bleuje.com/gifanimationsite/single/spiralwave/) | 2021 | ⭐⭐⭐ | replacement technique, mesh, spiral wave |


Most animations rely a lot on delay/offset techniques (something normal when time is involved :) ). Most of them also use basic object oriented programming.


#### About ratings

Please note that these ratings are highly subjective and are intended to serve as a rough guide for navigating the collection. While it's not ideal, they offer some insight into the complexity of understanding the code.

---

# Motivation and information

During my early months exploring animations with Processing, I stumbled upon the source code of some captivating gifs created by [beesandbombs (Dave)](https://beesandbombs.com/). Although I only examined a fraction of his [code examples](https://gist.github.com/beesandbombs), I made the effort to comprehend them as much as possible. This experience significantly influenced my skills – I discovered new techniques, had some enigmas unraveled, improved my mathematical approach, and improved my workflow. I even adopted Dave's motion blur template.

Over the years, I've shared numerous source codes from my animations. However, I often presented these codes in their raw form, as they appeared once I completed each animation. This approach allowed me to genuinely reveal my work with minimal effort while also showcasing the mathematical concepts behind them. My primary focus was always on the visual outcome, rather than perfecting the code's aesthetics.

With the support and encouragement I've received, I believe that sharing my animation creation process might hold value for others. I do not claim that my code is ideally suited for educational purposes, but I believe that, by refining it, others could potentially gain knowledge and improve their skills from studying my work – similar to my own experience with beesandbombs.

The aim of this project is to compile a selection of animation source codes that I find noteworthy, while enhancing and clarifying them through clearer, commented code. As I continue to add new examples and refine existing ones, this project should be a permanent work in progress. Although the code may have imperfections (e.g., suboptimal variable names, algorithmic flaws or quite poor factoring), I hope it represents a meaningful improvement over my previously shared work.

**Prerequisites:** To better understand the examples, I suggest first exploring the [**tutorials on my website**](https://bleuje.com/tutorials/). In particular, the "[Replacement Technique](https://bleuje.com/tutorial4/)" and the tutorial about beesandbombs' [motion blur template](https://bleuje.com/tutorial6/) seem helpful for providing context and foundational knowledge.

I hope that this collection of animation source code might serve as a helpful educational resource for those interested in delving deeper into the world of Processing-based animations. I hope that my work could inspire and support others on their creative journeys, just as beesandbombs' work has done for me.

## Acknowledgments and Licensing

This repository includes animations that utilize a [motion blur template](https://bleuje.com/tutorial6/) created by Dave. I have permission from him to use this template in my work.

Please note that while the motion blur template is available for use, the rest of the source code in this repository is generally protected under my copyright, and all rights are reserved. If you wish to use any part of my source code for your own projects or any other purpose, please contact me to obtain permission.
