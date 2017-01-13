---
#
# Use the widgets beneath and the content will be
# inserted automagically in the webpage. To make
# this work, you have to use › layout: frontpage
#
layout: frontpage
header: no
#
# Use the call for action to show a button on the frontpage
#
# To make internal links, just use a permalink like this
# url: /getting-started/
#
# To style the button in different colors, use no value
# to use the main color or success, alert or secondary.
# To change colors see sass/_01_settings_colors.scss
#
#callforaction:
#  url: https://tinyletter.com/feeling-responsive
#  text: Inform me about new updates and features ›
#  style: alert
permalink: /index.html
#
# This is a nasty hack to make the navigation highlight
# this page as active in the topbar navigation
#
homepage: true
---

### WORK IN PROGRESS

{% include alert text='This web-site is still work in progress. Please refrain from mentioning this web-site.' %}

<div id="videoModal" class="reveal-modal large" data-reveal="">
  <div class="flex-video widescreen vimeo" style="display: block;">
    <iframe width="1280" height="720" src="https://www.youtube.com/embed/3b5zCFSmVvU" frameborder="0" allowfullscreen></iframe>
  </div>
  <a class="close-reveal-modal">&#215;</a>
</div>

## Results Overview {#results}

The summary table with our classification of *MPX security levels*---from lowest L1 to highest L6---highlights the trade-off between __security__ (number of undetected *RIPE bugs* and *Other bugs* in benchmarks), __usability__ (number of programs *Broken* because of the applied approach), and __performance overhead__ (average *Perf* overhead w.r.t. native executions).
AddressSanitizer is shown for comparison in the last row.
SafeCode and SoftBound are *not* shown due to their instability: a large fraction of programs broke under these approaches.

Results are shown for GCC versions of MPX and AddressSanitizer.
In addition, ICC-MPX results are shown in brackets; note that L5 is not applicable to ICC-MPX.
For L6, performance overheads are not shown since too few programs executed correctly at this security level, and averaged results would not be meaningful.

| Approach                                                   | Detects                        | [RIPE bugs](/security#ripe)          | [Other bugs](/security#others)      | [Broken](/usability)           | [Perf (&times;)](/performance) |
|:-----------------------------------------------------------|:-------------------------------|-------------------:|----------------:|-----------------:|---------------:|
| **Native**: no protection                                  | ---                            | **64**&ensp;(34)   | **6**&ensp;(3)  | **0**&ensp;(0)   | **1.00**&ensp;(1.00)            |
| **MPX** security levels: |
| &ensp;&ensp;**L1**: only-writes and no narrowing of bounds | inter-object overwrites        | **14**&ensp;(14)   | **3**&ensp;(0)  | **3**&ensp;(5)   | **1.29**&ensp;(1.18)           |
| &ensp;&ensp;**L2**: no narrowing of bounds                 | &ensp;+ inter-object overreads | **14**&ensp;(14)   | **3**&ensp;(0)  | **2**&ensp;(8)   | **2.39**&ensp;(1.46)           |
| &ensp;&ensp;**L3**: only-writes and narrowing of bounds    | all overwrites*                | **14**&ensp;(0)    | **2**&ensp;(0)  | **4**&ensp;(7)   | **1.30**&ensp;(1.19)           |
| &ensp;&ensp;**L4**: narrowing of bounds (default)          | &ensp;+ all overreads*         | **14**&ensp;(0)    | **0**&ensp;(0)  | **4**&ensp;(9)   | **2.52**&ensp;(1.47)           |
| &ensp;&ensp;**L5**: + `fchkp-first-field-has-own-bounds`*  | &ensp;+ all overreads          | **0**&ensp;(--)    | **0**&ensp;(--) | **6**&ensp;(--)  | **2.52**&ensp;(--)           |
| &ensp;&ensp;**L6**: + `BNDPRESERVE=1` (protect all code)   | all overflows in all code      | **0**&ensp;(0)     | **0**&ensp;(0)  | **34**&ensp;(29) | --            |
| **AddressSanitizer**                                       | inter-object overflows         | **12**             | **3**           | **0**      | **1.55**           |

<sup>
\* except intra-object overwrites & overreads through the first field of struct, level 5 removes this limitation (only relevant for GCC version)
</sup>

### Lessons Learned {#lessons}

**Lesson 1: Intel MPX is not a silver bullet.**
MPX is a promising technology: (1) it provides the strongest possible security guarantees, (2) it instruments most programs transparently and correctly, (3) its ICC incarnation has moderate overheads of 20-50%, (4) it can interoperate with unprotected legacy libraries, and (5) its protection level is easily configurable.
However, by design [MPX can break programs](/usability) that violate the C standard memory model but are otherwise perfectly functional: some of these programs would require intrusive changes to execute under MPX.
Moreover, [performance overheads are still too high](/performance) for MPX to be used in production.

**Lesson 2: Intel MPX is not production-ready.**
MPX support has been available for around two years for GCC and ICC compilers.[^clang]
At the hardware level, some MPX instructions are [very slow](/microbenchmarks#mpxinstr) and some have [unjustified data dependencies](/performance#ipc).
At the compiler level, GCC-MPX has [severe performance issues](/performance) whereas ICC-MPX has [a number of compiler bugs](/usability).
At the runtime-support level, both GCC and ICC provide only a small subset of function wrappers for the C standard library, thus missing bugs such as the [Nginx `recv` bug](case-studies/#security-1).

**Lesson 3: Intel MPX does not support multithreading.**
Current incarnation of MPX has no support for multithreaded programs.[^multi]
[Our microbenchmarks](microbenchmarks/#multithreading) show that an MPX-protected multithreaded program can have both false positives (false alarms) and false negatives (missed bugs).
Until this issue is fixed---either at the SW or at the HW level---MPX cannot be considered safe in multithreaded environments.
Unfortunately, we do not see a simple fix to this problem that would *not* affect performance adversely.

**Lesson 4: Intel MPX has varying performance on real-world server applications.**
We tested Intel MPX on three real-world case-studies: Apache, Nginx, and Memcached.
For [Apache](/case-studies#apache) and [Nginx](/case-studies#nginx), MPX performed well and on par with AddressSanitizer, achieving 85-95% of native throughput.
For [Memcached](/case-studies#memcached), however, MPX could reach only 50% throughput, performing much worse than AddressSanitizer.

**Lesson 5: AddressSanitizer is currently the best solution for debugging and security.**
For comparison with MPX, we tried our best to evaluate open-source state-of-the-art techniques for memory safety.[^techniques]
In our experience, AddressSanitizer is the best choice in terms of performance, usability, and security, even though it provides weaker guarantees than MPX.
The other two techniques---SoftBound and SafeCode research prototypes---are unstable and cannot compile/run correctly many of the evaluated programs.


[^clang]: Interestingly, there seem to be no plans to port Intel MPX to Clang/LLVM; a discussion (started by us) can be found in the [LLVM mailing list](http://lists.llvm.org/pipermail/llvm-dev/2016-January/094620.html).
[^multi]: Surprisingly, Phoenix and PARSEC multithreaded programs experienced no MPX-related issues; we believe it was a matter of luck.
[^techniques]: We intentionally chose three different techniques: AddressSanitizer represents a *trip-wire* approach to memory safety, SafeCode -- *object-based* approach, and SoftBound -- *pointer-based* approach.