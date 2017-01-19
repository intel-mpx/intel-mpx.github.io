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

# Intel MPX Explained

This web-site contains complete results of the evaluation of Intel Memory Protection Extensions (Intel MPX) on Phoenix, PARSEC, and SPEC benchmark suites from three perspectives:

* **performance** -- performance and memory overheads,
* **security** -- qualitative and quantitative analysis of bugs/vulnerabilities detected,
* **usability** -- analysis of production quality and program-specific issues.

{% include alert text='Our work is still in progress. Please refrain from sharing and mentioning it.' %}

### What is Intel MPX?

In August 2015, Intel Memory Protection Extensions (Intel MPX) became available as part of the Skylake microarchitecture.
The goal of MPX was to provide an efficient protection against memory errors and attacks.
Here, by *memory errors*[^temporal] we understand errors that happen when a program reads from or writes to a different memory region than the one intended by the developer, e.g., buffer overflows and out-of-bounds accesses.
A *memory attack* is a different view on the same problem---a scenario in which an adversary gains access to the region of memory not allowed for use.

Although a few protection mechanisms had already existed before MPX, they were mainly implemented in software and caused significant slowdowns of protected programs.
MPX adds *hardware assistance* to memory protection and thus improves overall performance.

### What did we do in this work?

To our knowledge, there is no comprehensive evaluation of performance, security, and usability characteristics of MPX, neither from academic community nor from Intel itself.
Therefore, the goal of this work was to perform an *extensive and unbiased evaluation* of MPX.

To fully explore pros and cons of MPX, we put the results into perspective by comparing with existing software-based memory-safety mechanisms.
We chose three techniques that showcase main classes of memory safety:

* [AddressSanitizer](http://clang.llvm.org/docs/AddressSanitizer.html) is a _trip-wire_ (aka electric-fence) approach. This class surrounds all objects with regions of marked (poisoned) memory, so that any overflow will change values in this region and will be consequently detected.
* [SoftBound](https://www.cs.rutgers.edu/~santosh.nagarakatte/softbound/) is a _pointer-based_ approach. Such approaches keep track of pointer bounds (the lowest and the highest allowed address of a pointed-to memory region) and check each memory write and read against them.
* [SAFECode](http://safecode.cs.illinois.edu/) is an _object-based_ approach. Its main idea is enforcing the intended referent, i.e., making sure that pointer manipulations do not change the pointer's referent object.[^pointervsobject]

In this work, we present results of our experiments and discuss applicability of MPX.
We also analyze [microarchitectural details of MPX](/design) on a set of [microbenchmarks](/microbenchmarks), as well as differences between two existing implementations of MPX in two major compilers---ICC and GCC.

### Quick overview of results {#results}

The summary table with our classification of *MPX security levels*---from lowest L1 to highest L6---highlights the trade-off between [__security__](/security) (number of undetected *RIPE bugs* and *Other bugs* in benchmarks), [__usability__](/usability) (number of programs *Broken* because of the applied approach), and [__performance overhead__](/performance) (average *Perf* overhead w.r.t. native executions).
AddressSanitizer is shown for comparison in the last row.
SAFECode and SoftBound are *not* shown due to their instability: a large fraction of programs broke under these approaches.

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

Intel MPX is a promising technology: it provides the strongest possible security guarantees against spatial errors, it instruments most programs transparently and correctly, its ICC incarnation has moderate overheads of 20-50%, it can interoperate with unprotected legacy libraries, and its protection level is easily configurable.
However, our evaluation indicates that it is not yet mature enough for widespread use because of the following issues:

**Lesson 1: The compiler support is not mature enough.**
MPX support is available for GCC and ICC compilers.[^clang]
At the compiler level, GCC-MPX has [severe performance issues](/performance) whereas ICC-MPX has [a number of compiler bugs](/usability).
At the runtime-support level, both GCC and ICC provide only a small subset of function wrappers for the C standard library, thus not detecting bugs such as the [Nginx bug](case-studies/#security-1).
However, we believe that all these issues will be fixed in the future versions of the compilers.

**Lesson 2: The new instructions are not as fast as expected.**
There are two performance issues with MPX instructions:

* Loading/storing bounds registers from/to memory involves costly two-level address translation, which can contribute a significant share to the overhead.
* As our [experiments show](/performance#ipc), current Skylake processors perform bounds checking mostly sequentially.
[Our microbenchmarks](/microbenchmarks/#mpxchecks) indicate that this is caused by contention of MPX bounds-checking instructions on one of the execution ports.
If this functionality would be available on more ports, MPX would be able to use instruction parallelism to a higher extent and the overheads would be lower.

**Lesson 3: Intel MPX does not support multithreading.**
Current incarnation of MPX has no support for multithreaded programs.[^multi]
[Our microbenchmarks](microbenchmarks/#multithreading) show that an MPX-protected multithreaded program can have both false positives (false alarms) and false negatives (missed bugs).
Until this issue is fixed---either at the SW or at the HW level---MPX cannot be considered safe in multithreaded environments.
Unfortunately, we do not see a simple fix to this problem that would *not* affect performance adversely.

**Lesson 4: Intel MPX provides no temporal protection.**
Current design of MPX protects only against spatial (out-of-bounds accesses) but not temporal (dangling pointers) errors.
All other tested approaches---AddressSanitizer, SoftBound, and SAFECode---guarantee some form of temporal safety.
We believe MPX can be enhanced for temporal safety without harming performance, similar to SoftBound.

**In conclusion**, we can say that MPX has a potential for becoming the memory protection tool of choice, but currently, AddressSanitizer is the only production-ready option.
Even though it provides weaker security guarantees than the other techniques, its current implementation is better in terms of performance and usability.
SoftBound and SAFECode are research prototypes and they have issues that restrict their usage in real-world applications (although SoftBound provides higher level of security).
Both implementations of MPX do not support C programming idioms to the full extent, which causes a significant number of false positives in complex programs.
GCC implementation is less susceptible to them, but it comes at a cost of worse performance.

## Looking for more details?

* Complete description of Intel MPX can be found in **[Design](/design)**.
* Experimental setup can be found in **[Methodology](/methodology/)**.
* Isolated measurements of different aspects of Intel MPX are presented in **[Microbenchmarks](/microbenchmarks/)**.
* The evaluation itself consists of three parts:
    * **[Performance](/performance/)** page presents various run-time parameters;
    * **[Security](/security/)** page evaluates security guaranties;
    * **[Usability](/usability/)** page discusses various issues that appear when the considered protections are applied.
* Evaluation results on real-world applications are presented in **[Case Studies](/case-studies/)**.


[^temporal]: The current version of Intel MPX protects only against "spatial" errors and attacks (described above). There are also "temporal" errors that appear when trying to use an object before it was created or after it was deleted. MPX does not yet provide a protection against temporal errors.
[^pointervsobject]: In terms of created metadata, trip-wire approaches create "shadow memory" metadata for the whole available program memory, pointer-based approaches create bounds metadata per each pointer, and object-based approaches create bounds metadata per each object.
[^clang]: Interestingly, there seem to be no plans to port Intel MPX to Clang/LLVM; a discussion (started by us) can be found in the [LLVM mailing list](http://lists.llvm.org/pipermail/llvm-dev/2016-January/094620.html).
[^multi]: Surprisingly, Phoenix and PARSEC multithreaded programs experienced no MPX-related issues; we believe it was a matter of luck.
[^cets]: The SoftBound prototype we tested is based on the CETS+SoftBound version described in the paper ["CETS: Compiler-Enforced Temporal Safety for C" by Nagarakatte et al.](http://dl.acm.org/citation.cfm?id=1806657). CETS is the extension that adds protection against temporal errors.