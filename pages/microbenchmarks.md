---
layout: page-fullwidth
show_meta: false
title: "Microbenchmarks"
subheadline:
teaser:
header: no
permalink: "/microbenchmarks/"
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


## Latency and Throughput of MPX Instructions  {#mpxinstr}

The following table shows the latency-throughput results of Intel MPX instructions.
For this evaluation, we extended the scripts used to build Agner Fog's instruction tables.[^agnerfog]
Our scripts can be [downloaded here]({{ site.url }}{{ site.baseurl }}/code/asm_measurements.zip).

In our extension, we wrote a loop with 1,000 copies of an instruction under test and run the loop 100 times. This gives us 100,000 executions in total. We run each experiment 10 times to make sure the results were not influenced by external factors.
For each run, we initialize all BND registers with dummy values to avoid interrupts caused by failed bound checks.

| Instruction            | Latency | Throughput |   | P0 | P1 | P2 | P3 | P4 | P5 | P6 | P7 |
|:-----------------------|--------:|-----------:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `bndmk b, m`           | 2       | 2          |   | 1  | 1  |    |    |    | 1  | 1  |    |
| `bndcl b, m`           | 3       | 1          |   | 2  | 1  |    |    |    |    | 2  |    |
| `bndcl b, r`           | 1       | 2          |   |    | 1  |    |    |    |    | 1  |    |
| `bndcu b, m`           | 3       | 1          |   | 2  | 1  |    |    |    |    | 2  |    |
| `bndcu b, r`           | 1       | 2          |   |    | 1  |    |    |    |    | 1  |    |
| `bndmov b, m`          | 3       | 1          |   | 1  | 1  |    | 1  |    |    |    |    |
| `bndmov b, b`          | 1       | 2          |   | 1  | 1  |    |    |    | 1  | 1  |    |
| `bndmov m, b`          | 10      | 1/2        |   |    | 2  | 3  | 3  | 1  |    |    | 3  |
| `bndldx b, m`          | 12      | 1/2        |   | 2  | 2  | 1  | 1  |    | 1  | 1  |    |
| `bndstx m, b`          | 18      | 1/3        |   |    | 3  | 2  | 2  | 1  |    |    | 3  |

{% include alert text='**Note 1**: `bndcu` has a one’s complement version `bndcn`, we skip it for clarity.' %}

{% include alert text='**Note 2**: Ideally, we would measure throughput for the *parallel case* and latency for the *serial one*. The later case is noise-free, but we were not able to create the data dependency for most of the MPX instructions. Therefore, we resorted to estimating this metric as: *Latency = Number of ports / Throughput*.' %}

As expected, most operations have latencies of 1-2 cycles, e.g., `bndcl` and `bndcu` in registers have a minimal latency of one cycle.
The serious bottleneck is storing/loading the bounds with `bndstx` and `bndldx` since they undergo a complex algorithm of accessing bounds tables.


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## OS Bounds Tables Overhead  {#os}

Intel MPX relies on the operating system to manage special Bounds Tables (BTs) that hold pointer metadata.
To illustrate the additional overhead of allocating and de-allocating BTs, two microbenchmarks showcase the worst case scenarios.
The source code for them [can be found here]({{ site.url }}{{ site.baseurl }}/code/table_allocation.c).

The first microbenchmark stores a large set of pointers in such memory locations that each of them will have a separate BT, i.e., this benchmark indirectly creates a huge amount of bounds tables.
The second one does the same, but additionally frees all the memory right after it has been assigned, thus triggering BT de-allocation.

The characteristics of microbenchmarks:

* working with 3,000 BTs
* average over 10 runs
* compilation flags:
  * native version: `-g -O0`
  * MPX version: `-mmpx -fcheck-pointer-bounds -lmpx -lmpxwrappers -g -O0`

Note that we disabled all compiler optimizations to showcase the influence of OS alone.

The following table shows the impact of OS managing BTs, i.e., overheads of MPX version in performance and number of instructions w.r.t. native.

|                              | Perf   | Instr in user space  | Instr in kernel space |
|:-----------------------------|-------:|---------------------:|----------------------:|
| Only allocation              | 2.33×  | 7.5%                 | 160%                  |
| Allocation and de-allocation | 2.25×  | 10%                  | 139%                  |

In both cases, most of the runtime parameters (cache locality, branch misses, etc.) of the MPX-protected version are equivalent to the native one.
However, the performance overhead is noticeable -- more than 2 times.
It is caused by a single parameter that varies -- the number of instructions executed in the kernel space.
(Note how the number of instructions executed in the user space increases only slightly.)
It means that the overhead is caused purely by the BT management in the kernel.

We conclude that OS can account for performance overhead of 2.3× in the worst case.

More statistics collected can be found here: [os_microbenchmark.md]({{ site.url }}{{ site.baseurl }}/code/os_microbenchmark.md).


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Performance microbenchmarks  {#performance}

Below are the four microbenchmarks, each highlighting a separate MPX feature:

* [arraywrite]({{ site.url }}{{ site.baseurl }}/code/arraywrite.c): writing to memory (stress `bndcl` and `bndcu`)
* [arrayread]({{ site.url }}{{ site.baseurl }}/code/arrayread.c): reading from memory (stress `bndcl` and `bndcu`)
* [struct]({{ site.url }}{{ site.baseurl }}/code/struct.c): writing in an inner array inside a struct (the bounds-narrowing feature via `bndmk` and `bndmov`)
* [ptrcreation]({{ site.url }}{{ site.baseurl }}/code/ptrcreation.c): assigning new values to pointers (stress `bndstx`)

All microbenchmarks were compiled with `-O2` optimizations.

Performance results:

<img class="t20" width="95%" src="{{ site.urlimg }}micro_perf.jpg" alt="Performance overheads of microbenchmarks">

**Observation 1**: `arraywrite` and `arrayread` represent the bare overhead of bounds-checking instructions (all in registers), 50% in this case. `struct` has a higher overhead of 2.1−2.8× due to the more expensive making and moving of bounds to and from the stack. 5× overhead of `ptrcreation` is due to storing of bounds -- the most expensive MPX operation.

**Observation 2**:
There is a 25% difference between GCC and ICC in `arraywrite`. This is the effect of optimizations: GCC’s MPX pass blocks loop unrolling while ICC’s implementation takes  advantage of it. (Interestingly, the same happened in case of `arrayread` but the native ICC version was optimized even better, which led to a relatively poor performance of ICC’s MPX.)

**Observation 3**:
The overhead of `arrayread` becomes negligible with the only-writes MPX version: the only memory accesses in this benchmark are reads which are left uninstrumented. The same logic applies to `struct` -- disabling narrowing of bounds effectively removes expensive `bndmk` and `bndmov` instructions and lowers performance overhead to a bare minimum.

{% include alert text='Raw results can be found in the [repository](https://github.com/OleksiiOleksenko/mpx_evaluation/tree/master/raw_results/micro).' %}


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

## Multithreading microbenchmark  {#multithreading}

Intel MPX has fundamental problems with multithreading support.
In a nutshell, the problem arises because of the **non-atomic** way MPX loads and stores pointer bounds via its `bndldx` and `bndstx` instructions whenever a real pointer is loaded/stored from/to memory.
More information is provided in our paper[^mpxexplained] and in other sources[^chisnall].

We constructed two test cases that break MPX in a multithreaded environment: one that leads to a *false positive* (false alarm) and one that leads to a *false negative* (undetected real bug).
The test cases roughly work as follows; see our paper for more details.
A "pointer bounds" data race happens on the `arr` array of pointers. The background thread fills this array with all pointers to the first or to the second object alternately. Meanwhile, the main thread accesses a whatever object is currently pointed-to by the array items. Note that depending on the value of the constant offset, the original program is either always-correct or always-buggy: if offset is zero, then the main thread always accesses the correct object, otherwise it accesses an incorrect, adjacent object.

The test cases are compiled and run as follows:

* false negative:
  * [source code]({{ site.url }}{{ site.baseurl }}/code/multithreading_fn.c)
  * compile at `-O1` to have simple non-vectorized asm
  * run with `CHKP_RT_MODE=count CHKP_RT_PRINT_SUMMARY=1 CHKP_RT_VERBOSE=0 ./gcc_mpx/multithreading_fn`
  * Results:
    * in *correct* MPX implementation, output must be *10,000,000* (`ITERATIONS*MAXSIZE`)
    * in current GCC and ICC implementations, output is **less** than 10,000,000 (due to broken multithreading)
* false positive:
  * [source code]({{ site.url }}{{ site.baseurl }}/code/multithreading_fp.c)
  * compile at `-O1` to have simple non-vectorized asm
  * run with `CHKP_RT_MODE=count CHKP_RT_PRINT_SUMMARY=1 CHKP_RT_VERBOSE=0 ./gcc_mpx/multithreading_fp`
  * Results:
    * in *correct* MPX implementation, no `#BR` exception must be output
    * in current GCC and ICC implementations, output is `#BR` exception **nondetermenistically** (due to broken multithreading)

{% include alert text='**Note**: Make sure the test cases run on two cores!' %}


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->


[^agnerfog]: [http://www.agner.org/optimize/instruction_tables.pdf](http://www.agner.org/optimize/instruction_tables.pdf)

[^chisnall]: David Chisnall, Colin Rothwell, Robert N.M. Watson, Jonathan Woodruff, Munraj Vadera, Simon W. Moore, Michael Roe, Brooks Davis, and Peter G. Neumann. 2015. Beyond the PDP-11: Architectural Support for a Memory-Safe C Abstract Machine. In ASPLOS'2015.

[^mpxexplained]: TBD