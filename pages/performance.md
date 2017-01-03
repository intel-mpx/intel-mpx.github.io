---
layout: page-fullwidth
show_meta: false
title: "Performance Evaluation"
subheadline:
teaser:
header: no
permalink: "/performance/"
---

<div class="row">
<div class="medium-4 medium-push-8 columns" markdown="1">
<div class="panel radius" markdown="1">
**Table of Contents**
{: #toc }
*  TOC
{:toc}
</div>
</div><!-- /.medium-4.columns -->

<div class="medium-8 medium-pull-4 columns" markdown="1">

To evaluate the runtime parameters of MPX, we have tested three benchmark suits: Phoenix 2.0, PARSEC 3.0 and SPEC CPU2006 (see [methodology](/methodology#benchmarks) for details).
To put the results into a context, we measured not only the two implementations of MPX, but also SafeCode, SoftBound and AddressSanitizer.

## Performance overhead

The first parameter we will consider is slowdown of a protected application:

</div><!-- /.medium-8.columns -->
<div class="medium-12 medium-pull-12 columns" markdown="1">

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_perf.jpg" alt="Performance overheads of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_perf.jpg" alt="Performance overheads of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_perf.jpg" alt="Performance overheads of SPEC">

In most of the cases, the overheads appear simply because of the larger number of instructions that have to be executed in a protected application.
It can be clearly seen if we compare the performance overheads in previous figures and the instruction inflation; often the figures repeat each other.

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_instr.jpg" alt="Instruction overheads of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_instr.jpg" alt="Instruction overheads of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_instr.jpg" alt="Instruction overheads of SPEC">

But it raises another question: where do the additional instructions come from?
Mainly, they come from instrumentation of memory accesses and from wrappers on memory management functions.
Next figures prove it: the higher is the portion of memory accesses in the native version, the more code is required to protect it.

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_native_mem_access.jpg" alt="Native memory accesses of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_native_mem_access.jpg" alt="Native memory accesses of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_native_mem_access.jpg" alt="Native memory accesses of SPEC">

In MPX-protected applications, instruction overhead may also come from management of Bounds Tables.
Since it is performed by OS, it increases the number of executed instruction in kernel.
On our [microbenchmarks](/microbenchmarks#os) we shown that it may cause a slowdown of more than 100%. 
Nevertheless, in real applications, this factor does not seem to have a noticeable impact.
Even those applications that have to create hundreds of BTs (fluidanimate, canneal, dedup), get a minor slowdown in comparison to other factors. 

Instruction overhead is not the sole parameter that influences performance.
In the case of MPX, the second most important factor is the type of instructions that are used in instrumentation.
In particular, storing (bndstx) and loading (bndldx) bounds require two-level address translation, which is a very expensive operation and it can break cache locality.
To prove it, we measured the shares of MPX instructions in the total number of instructions of each application:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_mpxcount.jpg" alt="MPX instructions of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_mpxcount.jpg" alt="MPX instructions of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_mpxcount.jpg" alt="MPX instructions of SPEC">

We can see the direct correlation between these two instructions and lower IPC levels.
For example, when Matrix Multiply is protected with ICC, the protection almost exclusively consists of bounds checks and, accordingly, there is a direct mapping between instruction and performance overheads. 
However, since the GCC version is less optimized and it has to use bounds loading, its performance overhead is higher.

ICC-protected Word Count may seem to be a counterexample to this rule because it has many bound loads and stores, and at the same time, the slowdown is smaller than the instruction overhead. 
To understand this behavior, we will look at the cache locality of the benchmarks:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_cache.jpg" alt="Cache behavior of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_cache.jpg" alt="Cache behavior of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_cache.jpg" alt="Cache behavior of SPEC">

It appears that native version of Word Count has a significant number of L1 and L2 cache misses.
They have very high performance cost and therefore, can mask the overhead of memory protection. 

When compared to other approaches, MPX shows much better results than both SoftBound and SafeCode.
And it is no wonder---they are both implemented purely in software, when MPX has additional support from hardware.
Nevertheless, AddressSanitizer proves to be a worthy competitor, with better performance than GCC MPX and comparable to ICC MPX.
But as we will see later, it comes with a price of lower security guaranties.

## Memory consumption

The memory overhead measurements are presented in the next figures:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_mem.jpg" alt="Memory consumption overheads of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_mem.jpg"  alt="Memory consumption overheads of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_mem.jpg"    alt="Memory consumption overheads of SPEC">

On average, MPX requires 53 % more memory in the ICC version and 154 % in the GCC.
It is a significant improvement over AddressSanitizer and it comes from two-level address translation scheme.
AddressSanitizer creates a ``shadow zone'' that is directly mapped to the main memory and therefore, can be quite big.
On the other hand, MPX has an intermediary Bounds Directory that trades lower memory consumption for longer assess time.

## MPX features

MPX has two main features that influence both performance and security guaranties: bounds narrowing and only-write protection.
When *bounds narrowing* is applied, each field of an object has its own bounds.
It allows to detect overflows not only between objects, but also between fields inside a single object.
Correspondingly, when this feature increases security level, but may harm performance.
_Only write protection_, on the other side, improves performance by disabling checks on memory reads.

The comparison of these features is presented in next two sets of figures.

Firstly, influence on performance:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_mpx_feature_perf.jpg" alt="Performance overheads of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_mpx_feature_perf.jpg" alt="Performance overheads of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_mpx_feature_perf.jpg" alt="Performance overheads of SPEC">

Secondly, influence on memory consumption:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_mpx_feature_mem.jpg" alt="Memory consumption overheads of Phoenix">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_mpx_feature_mem.jpg"  alt="Memory consumption overheads of Parsec">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_mpx_feature_mem.jpg"    alt="Memory consumption overheads of SPEC">

As we can see, bounds narrowing has very small impact on performance because it does not change the number of checks.
At the same time, it may increase memory consumption because it has to keep more bounds.
Only write checking has the opposite effect - having to instrument less code reduces the slowdown but barely has any impact on memory consumption.

## Multithreading

To evaluate the influence of multithreading, we measured and compared execution times of all benchmarks on 2 and 8 threads.
The approach for enabling multithreading was different for different benchmark suites: for Phoenix it was enough to set a corresponding compilation flag; Parsec required an alternative version of the source code (supplied with the suite).
SPEC does not have a multithreaded version at all.
Moreover, both SoftBound and SafeCode are not thread-safe and therefore were excluded from measurements.

Our results are presented in the following figures:

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_multi.jpg" alt="Multithreading (Phoenix)">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_multi.jpg"  alt="Multithreading (Parsec)">

As we can see, the difference is minimal.
For MPX, it is caused by the absence of multithreading support, which means that no additional code is executed in parallel versions.
The results of AddressSanitizer are similar because it does not require explicit synchronization---it is thread-safe by design.

## Experiments with varying input sizes 

### Performance

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_var_input_perf.jpg" alt="Varying inputs - performance (Phoenix)">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_var_input_perf.jpg"  alt="Varying inputs - performance (Parsec)">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_var_input_perf.jpg"    alt="Varying inputs - performance (SPEC)">

### Memory consumption

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_var_input_mem.jpg" alt="Varying inputs - memory (Phoenix)">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_var_input_mem.jpg"  alt="Varying inputs - memory (Parsec)">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_var_input_mem.jpg"    alt="Varying inputs - memory (SPEC)">

## Other statistics

This data was removed from the main paper since it does not add more information to the existing discussion. 
Nevertheless, we leave it here for the sake of completeness.

**Branch instructions and TLB locality**

<img class="t20" width="100%" src="{{ site.urlimg }}phoenix_misc_stat.jpg" alt="Branches and TLB (Phoenix)">
<img class="t20" width="100%" src="{{ site.urlimg }}parsec_misc_stat.jpg"  alt="Branches and TLB (Parsec)">
<img class="t20" width="100%" src="{{ site.urlimg }}spec_misc_stat.jpg"    alt="Branches and TLB (SPEC)">