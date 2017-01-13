---
layout: page-fullwidth
show_meta: false
title: "Usability Evaluation"
subheadline:
teaser:
header: no
permalink: "/usability/"
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

## MPX Usability  {#mpxusability}

The below figure highlights the usability of MPX, i.e., the number of MPX-protected programs that fail to compile correctly and/or need significant code modifications. Note that many programs can be easily fixed; we do not count them as broken (see the refined table below for details). MPX security levels are based on our own classification and correspond to the stricter protection rules, where level 0 means unprotected native version and 6---the most secure MPX configuration. In total, our evaluation covers 38 programs from the Phoenix, PARSEC, and SPEC benchmark suites.

<img class="t20" width="75%" src="{{ site.urlimg }}usability.jpg" alt="Number of MPX-broken programs">

As can be seen, around 10% of programs break already at the weakest level 1 of MPX protection (without narrowing of bounds and protecting only writes).
At the highest security level 6 (with enabled `BNDPRESERVE`), most of the programs fail.

As for other approaches, no programs broke under AddressSanitizer. For SafeCode, around 70% programs executed correctly (all Phoenix, half of PARSEC, and 3/4 of SPEC).  SoftBound---being a prototype implementation---showed poor results, with only simple programs surviving (all Phoenix, one PARSEC, and 6 SPEC). See details below.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Refined Usability Table  {#usabilitytable}

The below table shows all changes made to the programs under test as well as reasons why some programs break at compile- or run-time. (Click to open in new tab.)

<a href="{{ site.urlimg }}results_table.jpg" target="_blank"><img class="t20" width="100%" src="{{ site.urlimg }}results_table.jpg" alt="Refined usability table"></a>

AddressSanitizer has no usability issues---by design it makes no assumptions on the C standard with respect to the memory model.
Also, it is the most stable tested product, fixed and updated with each new version of GCC and Clang.

On the contrary, SoftBound and SafeCode are research prototypes.
They work perfectly with very simple programs from Phoenix, but are not able to compile/run correctly the more complicated benchmarks from Parsec and SPEC.
Moreover, SoftBound does *not* support multithreading, and any multithreaded program immediately fails under it.

**Observation 1**: Both GCC-MPX and ICC-MPX break most programs on Level 6 (with `BNDPRESERVE=1`).
This is because `BNDPRESERVE` does *not* clear bounds on pointers transferred from/to unprotected legacy libraries.
This means that any pointer returned from or modified by any legacy library (including C standard library) will almost certainly contain wrong bounds.
Because of this, 89% of GCC-MPX and 76% of ICC-MPX programs break.
These cases are represented as gray boxes.

* Note that for Phoenix, GCC-MPX fails in most cases while ICC-MPX works correctly. This is because of a slight difference in libc wrappers: all the failing programs use `mmap64` function which is correctly wrapped by ICC-MPX but ignored by GCC-MPX. Thus, in the GCC case, the newly allocated pointer contains no bounds which (under `BNDPRESERVE=1`) is treated as an out-of-bounds violation.
* One can wonder why some programs *still* work even if interoperability with C standard library is broken. The reason is that programs like `kmeans`, `pca`, and `lbm` require *literally no* external functions except `malloc`, `memset`, `free`, etc.---which are provided by the wrapper MPX libraries.

**Observation 2**: Some programs break due to *memory model violation*.

* `ferret` and `raytrace` both have structs with the first field used to access other fields in the struct (a common practice that is actually disallowed by the C standard). ICC-MPX disallows this behavior when bounds narrowing is enabled. GCC-MPX allows such behavior by default and has a special switch to tighten it (`-fno-chkp-first-field-has-own-bounds`) which we classify as Level 5.
* `gcc` has its own complex memory model with bit-twiddling, type-casting, and other practices deprecated by the C standard. This is why both GCC-MPX and ICC-MPX break as soon as bounds narrowing is enabled.
* `soplex` manually modifies pointers-to-object from one address to another using pointer arithmetic, without any respect towards pointer bounds. By design, MPX cannot circumvent this violation of the C standard. (The same happens in `mcf` but only in one corner-case on test input.)
* `xalancbmk` performs a container-style subtraction from the base of a struct. This leads to GCC-MPX and ICC-MPX breaking when bounds narrowing is enabled.
* We also manually fixed some memory-model violations, e.g., flexible arrays with size 1 (`arr[1]`). These fixes are represented as yellow background.

**Observation 3**: In some cases, real bugs were detected (see also [security](/security#others)).

* Three bugs in `ferret`, `h264ref`, and `perlbench` were detected and fixed by us. These fixes are represented as blue background.
* Three bugs in `x264`, `h264ref`, and `perlbench` were detected *only* by GCC-MPX versions. These bugs are represented as red boxes. Note that ICC-MPX missed bugs in `h264ref` and `perlbench`. Upon debugging, we noticed that ICC-MPX narrowed bounds less strictly than GCC-MPX and thus missed the bugs. We were not able to hunt out the root cause, but presume it is due to different memory layouts generated by GCC and ICC compilers.

**Observation 4**: In rare cases, we hit compiler bugs in GCC and ICC.

* GCC-MPX had only one bug, an obscure "fatal internal GCC compiler error" on only-write versions of `xalancbmk`.
* ICC-MPX has an [autovectorization bug](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700675) triggered on some versions of `vips`, `gobmk`, `h264ref`, and `milc`.
* ICC-MPX has a ["wrong-bounds through indirect call" bug](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700550) triggered on some versions of `x264` and `xalancbmk`.
* ICC-MPX has a bug we could not identify triggered on `dealII`.
* We also manually fixed all manifestations of the [C99 VLA bug](https://software.intel.com/en-us/forums/intel-c-compiler/topic/701764) in ICC-MPX. These bugs are represented as pink background.


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


<!--
## Changes in Benchmarks  {#changes}

TODO: dump changes from our Wiki

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }
-->

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->
