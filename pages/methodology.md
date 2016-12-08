---
layout: page-fullwidth
show_meta: false
title: "Evaluation methodology"
subheadline:
teaser:
header: no
permalink: "/methodology/"
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

## Testbed

All the experiments were performed on the following setup:

#### Hardware

* Intel(R) Xeon(R) CPU E3-1230 v5 @ 3.40GHz
* 1 socket, 8 hyper-threads, 4 physical cores
* CPU caches: L1d = 32KB, L1i = 32KB, L2 = 256KB, shared L3 = 8MB
* 64 GB of memory

#### Network

For experiments on case studies (Apache, Nginx, Memcached), we used two machines with the network bandwidth between them equal to **938 Mbits/sec** as measured by iperf.


#### Software infrastructure

* Kernel: 4.4.0
* GLibC: 2.21
* Binutils: 2.26.1

#### Compilers

* GCC:
    * Version: 6.1.0
    * Configuration flags: `--enable-languages=c,c++ --enable-libmpx --enable-multilib --with-system-zlib`
* ICC:
    * Version: 17.0.0
* LLVM (AddressSanitizer):
    * Version: 3.8.0
    * Configuration flags (LLVM): `-G "Unix Makefiles" -DCMAKE_BUILD_TYPE="Release" -DLLVM_TARGETS_TO_BUILD="X86"`
* LLVM (SoftBound):
    * Version: 3.4.0
    * Configuration flags: `--enable-optimized --disable-bindings`
    * [Source](https://github.com/santoshn/softboundcets-34)
* LLVM (SafeCode):
    * Version: 3.2.0
    * Configuration flags: `-G "Unix Makefiles" -DCMAKE_BUILD_TYPE="Release" -DLLVM_TARGETS_TO_BUILD="X86"`
    * [Source](http://safecode.cs.illinois.edu/downloads.html)

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }
---


## Measurement tools

We've used the following tools for measurements:

* [perf stat](https://perf.wiki.kernel.org/index.php/Tutorial). It was our main tool, which we used to measure all CPU-related parameters. Full list includes:

```
-e cycles,instructions,instructions:u,instructions:k
-e branch-instructions,branch-misses
-e dTLB-loads,dTLB-load-misses,dTLB-stores,dTLB-store-misses
-e L1-dcache-loads,L1-dcache-load-misses
-e L1-dcache-stores,L1-dcache-store-misses
-e LLC-loads,LLC-load-misses
-e LLC-store-misses,LLC-stores
```

Not to introduce an additional error, we've measured these parameters by parts, 8 parameters at a time.

* [time](https://linux.die.net/man/1/time). Since `perf` doesn't provide capabilities for measuring physical memory consumption of a process, we had to use `time --verbose` and collect maximum resident set size.
* [Intel Pin](https://software.intel.com/en-us/articles/pin-a-dynamic-binary-instrumentation-tool). To gather MPX instruction statistics, we've used Pin tool, which allows to write custom binary instrumentations. Full code of our instrumentation can be found in the [repository](/404/).

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }
---

## Benchmarks

We used three benchmark suits in our evaluation: [Parsec 3.0](http://parsec.cs.princeton.edu/), [Phoenix 2.0](https://github.com/kozyraki/phoenix/tree/master/sample_apps) and [SPEC CPU 2006](https://www.spec.org/cpu2006/).
During our work, we found and fixed a set of bugs in them (see [Bugs in benchmarks](/bugs/) for details).

All the benchmarks were compiled together with the libraries they depend upon.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }
---

## Build types

#### GCC implementation of MPX

* compiler flags: `-fcheck-pointer-bounds -mmpx`
* linker flags: `-lmpx -lmpxwrappers`
* environment variables:

```sh
CHKP_RT_BNDPRESERVE="0"  # support of legacy code, i.e. libraries
CHKP_RT_MODE="stop"
CHKP_RT_VERBOSE="0"
CHKP_RT_PRINT_SUMMARY="0"
```

Subtypes:

* disabled bounds narrowing: `-fno-chkp-narrow-bounds`
* protecting only memory writes, not reads: `-fno-chkp-check-read`

#### ICC implementation of MPX

* compiler flags: `-check-pointers-mpx=rw`
* linker flags: `-lmpx`
* environment variables:

```sh
CHKP_RT_BNDPRESERVE="0"  # support of legacy code, i.e. libraries
CHKP_RT_MODE="stop"
CHKP_RT_VERBOSE="0"
CHKP_RT_PRINT_SUMMARY="0"
```

Subtypes:

* disabled bounds narrowing: `-no-check-pointers-narrowing`
* protecting only memory writes, not reads: `-check-pointers-mpx=write` instead of `-check-pointers-mpx=rw`


#### AddressSanitizer (both GCC and Clang)

* compiler flags: `-fsanitize=address`
* environment variables:

```sh
ASAN_OPTIONS="verbosity=0:\
detect_leaks=false:\
print_summary=true:\
halt_on_error=true:\
poison_heap=true:\
alloc_dealloc_mismatch=0:\
new_delete_type_mismatch=0"
```

Subtype:

* protecting only memory writes, not reads: `--param asan-instrument-reads=0`

#### SoftBound

* compiler flags: `-fsoftboundcets -flto -fno-vectorize`
* linker flags: `-lm -lrt` (runtime library is linked automatically)

#### SafeCode

* compiler flags: `-fmemsafety -g -fmemsafety-terminate -stack-protector=1`

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }
---

## Experiments

All experiments were executed 10 times and the results were averaged.
In case of Phoenix, each experiment was additionally preceded by a "dry run" - a run that was not recorded and served a sole purpose of putting the working set into cache.
The goal of this "dry run" was to decrease the variance in the results, since all Phoenix benchmarks are small and "cold" cache might have drastically slowed them down.

We performed the following types of experiments:

* normal: experiments on a single thread (serialized) and with fixed input
* multithreaded: experiments on 2, 4, and 8 threads
* variable inputs: experiments with increasing input size. In particular, we were doing 5 runs, each next one having twice bigger input than the previous

The received results were checked to fulfil the following criteria:

* application compiled successfully
* application run successfully (with normal exit code)
* the output is equal to the output of non-protected application (if it is stable)
* the coefficient of variation among results is less than 5 %

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }