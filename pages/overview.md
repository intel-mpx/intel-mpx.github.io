---
layout: page-fullwidth
show_meta: false
title: "Study overview"
subheadline:
teaser:
header: no
permalink: "/overview/"
---

This web-site presents complete results of our evaluation of Intel Memory Protection Extensions (Intel MPX) from three perspectives:

* **performance** -- performance and memory overheads,
* **security** -- qualitative and quantitative analysis of bugs/vulnerabilities detected,
* **usability** -- analysis of production quality and program-specific issues.

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

* [AddressSanitizer](http://clang.llvm.org/docs/AddressSanitizer.html) is a _trip-wire_ approach. This class surrounds all objects with regions of marked (poisoned) memory, so that any overflow will change values in this region and will be consequently detected.
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

**Lesson 1: New MPX instructions are not as fast as expected.**
There are two performance issues with MPX instructions which together lead to tangible runtime overheads of 20−50% (in the ICC case):

* Loading/storing bounds registers from/to memory involves costly two-level address translation, which can contribute a significant share to the overhead.
* As our [experiments show](/performance#ipc), current Skylake processors perform bounds checking mostly sequentially.
[Our microbenchmarks](/microbenchmarks/#mpxchecks) indicate that this is caused by contention of MPX bounds-checking instructions on one of the execution ports.
If this functionality would be available on more ports, MPX would be able to use instruction parallelism to a higher extent and the overheads would be lower.

**Lesson 2: The supporting infrastructure is not mature enough.**
MPX support is available for GCC and ICC compilers.[^clang]
At the compiler level, GCC-MPX has [severe performance issues](/performance) (150% overhead on average) whereas ICC-MPX has [a number of compiler bugs](/usability) (such that 10% of programs broke in our evaluation).
At the runtime-support level, both GCC and ICC provide only a small subset of function wrappers for the C standard library, thus not detecting bugs such as the [Nginx bug](/case-studies/#security-1).

**Lesson 3: MPX provides no temporal protection.**
Current design of MPX protects only against spatial (out-of-bounds accesses) but not temporal (dangling pointers) errors.
All other tested approaches---AddressSanitizer, SoftBound, and SAFECode---guarantee some form of temporal safety.
We believe MPX can be enhanced for temporal safety without harming performance, similar to SoftBound.

**Lesson 4: MPX does not support multithreading transparently**
Current incarnation of MPX has no transparent support for multithreaded programs.[^multi]
[Our microbenchmarks](/microbenchmarks/#multithreading) show that an MPX-protected multithreaded program can have both false positives (false alarms) and false negatives (missed bugs and undetected attacks) if the application does not conform to C11 memory model or if the compiler does not update bounds in atomic primitives.
Until this issue is fixed---either at the software or at the hardware level---MPX cannot be considered safe in multithreaded environments.
Unfortunately, we do not see a simple fix to this problem that would *not* affect performance adversely.

**Lesson 5: MPX is not compatible with some C idioms.**
MPX [imposes restrictions on allowed memory layout](/design/#application) which conflict with several widespread C programming practices, such as intra-structure memory accesses and custom implementation of memory management.
This can result in unexpected program crashes and is hard to fix; we were not able to run correctly [8 − 13% programs](/usability/) (this would require substantial code changes).

**In conclusion**, we believe that MPX has a potential for becoming the memory protection tool of choice, but currently, AddressSanitizer is the only production-ready option.
Even though it provides weaker security guarantees than the other techniques, its current implementation is better in terms of performance and usability.
SoftBound and SAFECode are research prototypes and they have issues that restrict their usage in real-world applications (although SoftBound provides higher level of security).
Both implementations of MPX do not support C programming idioms to the full extent, which causes a significant number of false positives in complex programs.
GCC implementation is less susceptible to them, but it comes at a cost of worse performance.

We expect that most identified issues with Intel MPX will be fixed in future versions.
Still, support for multithreading and restrictions on memory layout are inherent design limitations of MPX which would require sophisticated solutions, which would in turn negatively affect performance.
We hope our work will help practitioners to better understand the benefits and caveats of Intel MPX, and researchers---to concentrate their efforts on those issues still waiting to be solved.


[^temporal]: The current version of Intel MPX protects only against "spatial" errors and attacks (described above). There are also "temporal" errors that appear when trying to use an object before it was created or after it was deleted. MPX does not yet provide a protection against temporal errors.
[^pointervsobject]: In terms of created metadata, trip-wire approaches create "shadow memory" metadata for the whole available program memory, pointer-based approaches create bounds metadata per each pointer, and object-based approaches create bounds metadata per each object.
[^clang]: Interestingly, there seem to be no plans to port Intel MPX to Clang/LLVM; a discussion (started by us) can be found in the LLVM mailing list [the link is temporary hidden while the paper is under submission] <!--[LLVM mailing list](http://lists.llvm.org/pipermail/llvm-dev/2016-January/094620.html).-->
[^multi]: Surprisingly, Phoenix and PARSEC multithreaded programs experienced no MPX-related issues; we believe it was a matter of luck.
[^cets]: The SoftBound prototype we tested is based on the CETS+SoftBound version described in the paper ["CETS: Compiler-Enforced Temporal Safety for C" by Nagarakatte et al.](http://dl.acm.org/citation.cfm?id=1806657). CETS is the extension that adds protection against temporal errors.
