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

As for other approaches, no programs broke under AddressSanitizer. For SAFECode, around 70% programs executed correctly (all Phoenix, half of PARSEC, and 3/4 of SPEC).  SoftBound---being a prototype implementation---showed poor results, with only simple programs surviving (all Phoenix, one PARSEC, and 6 SPEC). See details below.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Refined Usability Table  {#usabilitytable}

The below table shows all changes made to the programs under test as well as reasons why some programs break at compile- or run-time. (Click to open in new tab.)

<a href="{{ site.urlimg }}results_table.jpg" target="_blank"><img class="t20" width="100%" src="{{ site.urlimg }}results_table.jpg" alt="Refined usability table"></a>

AddressSanitizer has no usability issues---by design it makes no assumptions on the C standard with respect to the memory model.
Also, it is the most stable tested product, fixed and updated with each new version of GCC and Clang.

On the contrary, SoftBound and SAFECode are research prototypes.
They work perfectly with very simple programs from Phoenix, but are not able to compile/run correctly the more complicated benchmarks from PARSEC and SPEC.
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


## All Bugs in Benchmarks  {#changes}

Below is the list of changes/fixes that were applied to benchmarks, as well as those issues that could not be easily fixed (real bugs and complex compiler bugs).

### Phoenix

* **kmeans: performance fix**.
Changed the values of `DEF_DIM=5` (previously `3`) and `DEF_GRID_SIZE=10000` (previously `1000`) to increase the execution time.


### PARSEC

* **blackscholes: ICC compiler bug fix**.
Multithreaded version failed under all ICC-MPX with error due to a declaration of a variable-length stack array (C99 feature) in `blackscholes.cpp:400`. Example line: `int tids[nThreads]` --- a stack-allocated int array. The fix: declaring arrays with constant: `int tids[MAX_THREADS]`.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/701764).

* **canneal: AddressSanitizer (Clang) bug fix**.
Multithreaded version segfaulted under AddressSanitizer (Clang). The problem was in a missing return value in `main.cpp:141`, in thread entry point `void* entry_pt(void* data)`. The fix: `return 0` in the end of this function. *Note* this is not a memory-safety problem, but a more strict interpretation of the C standard by AddressSanitizer under Clang/LLVM.

* **dedup: ICC compiler bug fix**.
Multithreaded version failed under all ICC-MPX with error due to a declaration of a variable-length stack array (C99 feature) in `encoder.c:1221`, `encoder.c:1229` and `encoder.c:1237`. Example line: `chunk_thread_args[conf->nthreads]` --- a stack-allocated int array. The fix: declaring arrays with constant: `chunk_thread_args[MAX_THREADS]`.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/701764).

* **ferret: buffer overflow fix**.
Ferret assumes RGB files, but some inputs were black and white.
In `image.c:image_read_rgb_hsv` the input file is assumed to have 3 components, one byte for red, green and blue accordingly.
But for some files `cinfo.output_components` is set to 1, that is those files were black and white.
So it looped through 3 times more data than was allocated: *classic buffer overflow*.
This bug was detected by all approaches.
The fix: skipping black and white input images (manually removed these input files).

* **ferret: buffer overflow fix (another)**.
In `cass.h:84`, an array of 1 element was defined in `struct _cass_vec_t`: `float_data[1]`. Later, the code looped over 9 elements in `extract.c:233`: `vec->u.float_data[k] = ...`. It is a *classic buffer overflow* which (fortunately) did not corrupt any memory. The fix: increasing array size: `float_data[14]`.

* **ferret (libjpeg lib): variable-sized array fix**.
There was a variable-sized array declared as `jpeg_natural_order[]`.
GCC-MPX with bounds-narrowing assumed zero size for this array.
The fix: declaring array with constant: `jpeg_natural_order[64+16]`.

* **ferret (libjpeg lib): memory model violation, wontfix**.
ICC-MPX with bounds-narrowing fails in `alloc_small` function (`jmemmgr.c:278`) because of incorrectly defined object sub-bounds: `hdr_ptr = mem->small_list[pool_id]`.
`mem` is of type `my_memory_mgr` and is a subfield (substruct) of the function argument `cinfo`, but originally this subfield is of type `jpeg_memory_mgr` (104 bytes in size and lacking `small_list` field).
The code needs to typecast `jpeg_memory_mgr` (104B-sized) to `my_memory_mgr` (>104B-sized), and ICC-MPX pass gets confused because of `cinfo->mem = &mem->pub` in `jmemmgr.c:1095`.
*Note* that it works correctly under GCC-MPX (`mem->pub` is the first subfield, and GCC-MPX by default uses `-fno-chkp-first-field-has-own-bounds` -- the first field has bounds of the whole object).

* **raytrace: memory model violation, wontfix**.
ICC-MPX with bounds-narrowing fails.
`RTVec_t` class (defined in `RTVec.hxx` + `RTVecBody.h`) has the first member `typename DataArray::AlignedDataType x`.
Actually, `x` is used as an array (the original 4B type is overflowed) via `DataType* data() { return &x; }` (in `RTVecBody.h`).
ICC-MPX narrows bounds in `data` function to only `x`, but it is later used to access beyond these 4 bytes.
*Note* that it works correctly under GCC-MPX (`x` is the first subfield, and GCC-MPX by default uses `-fno-chkp-first-field-has-own-bounds` -- the first field has bounds of the whole object).

* **swaptions: ICC compiler bug fix**.
Multithreaded version failed under all ICC-MPX with error due to a declaration of a variable-length stack array (C99 feature) in `HJM_Securities.cpp:270`. Example line: `int threadIDs[nThreads]` --- a stack-allocated int array. The fix: declaring array with constant: `int threadIDs[MAX_THREAD]`.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/701764).

* **vips (glib lib): flexible array fix**.
There was a flexible array in `gtype.c:246` in struct `_TypeNode` declared as `supers[1]`.
Later it was correctly malloced with greater size, but ICC-MPX and GCC-MPX with bounds-narrowing (both) always assume the size of `1`.
The fix: declaring array with zero size which MPX treats as boundless: `supers[0]`.

* **vips: variable-sized array fix**.
There was a variable-sized array declared as `im__sizeof_bandfmt[]` in `include/vips/image.h` and `iofuncs/util.c`.
GCC-MPX with bounds-narrowing assumed zero size for this array.
The fix: declaring array with constant: `im__sizeof_bandfmt[10]`.

* **vips: ICC compiler bug, wontfix**.
The bug triggers only on ICC-MPX with bounds-narrowing and in peculiar corner-cases (some ICC autovectorization optimization clashes with MPX instrumentation).
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700675).

* **x264: variable-sized array fix**.
There were variable-sized arrays declared as `x264_levels[]` and `x264_cpu_names[]`.
GCC-MPX with bounds-narrowing assumed zero size for these arrays.
The fix: declaring arrays with constants: `x264_levels[16]` and `x264_cpu_names[16]`.

* **x264: double-free bug fix**.
Fixed double-free bug as reported in [https://mailman.videolan.org/pipermail/x264-devel/2010-January/006717.html](https://mailman.videolan.org/pipermail/x264-devel/2010-January/006717.html).
The fix touches `set.c:x264_cqm_delete` function.
(This bug fix is not counted in usability study since it is temporal bug.)

* **x264: buffer overflow bug, wontfix**.
Buffer overflow bug as reported in [https://ffmpeg.org/pipermail/ffmpeg-devel/2013-March/141083.html](https://ffmpeg.org/pipermail/ffmpeg-devel/2013-March/141083.html).
It was detected only by GCC-MPX with bounds-narrowing.
In a nutshell, there is a benign buffer overwrite of `quant4_mf[4]` field in `x264_cqm_init` function (writes into non-existing fifth and sixth array items).
Without narrowing of bounds, GCC-MPX does not crash the program -- since the buffer overwrite is in-struct.
ICC-MPX does not detect this---most probably because ICC has another memory layout which hides the bug.
Wontfix: others simply ignored this bug and worked-around it until new version of x264, where bug disappeared.

* **x264: ICC compiler bug, wontfix**.
The bug triggers on all versions of ICC-MPX and in peculiar corner-cases (ICC-MPX pass incorrectly passes bounds through indirect call).
In `encoder_analyse.c:x264_mb_cache_fenc_satd`, the variable `fenc` incorrectly gets NULL bounds, which makes MPX later crash.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700550).

### SPEC

Note that we applied a [patch](https://github.com/google/sanitizers/blob/master/address-sanitizer/spec/spec2006-asan.patch) by AddressSanitizer authors.
This patch fixes bugs in perlbench and h264ref; we mention these bug fixes below.

* **dealII: Unknown bug, wontfix**.
All version of ICC-MPX instrument the libstdc++ library used by dealII.
Thus, `std::vector` operations are MPX-instrumented.
Somewhere in the middle of execution, `std::vector::~vector` destructor is called, which does `std::vector::erase` of all items, and this function fails due to incorrectly defined bounds.
Wontfix: the `#BR` exception happens far away from the bounds allocation that triggers it, so it is impossible to backtrack and identify the root cause.

* **gcc: flexible array fix**.
There were flexible arrays `fld[1]` and `elem[1]` in `rtl.h:201` and `rtl.h:224`.
At runtime, they were correctly malloced with greater sizes, but ICC-MPX and GCC-MPX with bounds-narrowing (both) always assume the size of `1`.
The fix: declaring arrays with big-enough sizes: `fld[250]` and `elem[20]`.

* **gcc: numerous memory model violations, wontfix**.
gcc has its own memory management, with bit twiddling, wild type casts, and complex structs.
Debugging it is hard.
In the end, there is a narrowing of bounds in `hashtable.c:ht_lookup` that creates too-narrow bounds, leading to false positive in ICC-MPX and GCC-MPX with bounds-narrowing (both).

* **gobmk: ICC compiler bug, wontfix**.
For ICC-MPX without bounds-narrowing, when compiled with `-O3`, gobmk creates a wrong bound for a global variable `board` (defined in `globals.c` as a huge char array).
Some conflicting optimization produces the exception-triggering code: `bndmk  bnd1,[r15+0x1]; bndcu  bnd1,[r12+rcx*1+0xd23934]`.
Here the first line creates bounds `{board, board+1}` of only two bytes, and the second line crashes with `#BR`.
Wontfix, we have not yet filed a bug report (cannot create a reproducible test case).

* **h264ref: buffer overflow fix**.
Buffer overflow in `mv-search.c:1093`. The line is: `for (dd=d[k=0]; k<16; dd=d[++k])` -- with an incorrect pre-increment.
The fix: ` for (dd=d[k=0]; k<16; dd=d[k++])` -- with correct post-increment.
This is a famous bug: [https://www.spec.org/cpu2006/Docs/faq.html#Run.05](https://www.spec.org/cpu2006/Docs/faq.html#Run.05).
(Also fixed in AddressSanitizer patch.)

* **h264ref: buffer overflow, wontfix**.
The in-struct buffer overflow happens in `macroblock.c:writeMotionInfo2NAL`.
The offending code: `int blc_size[8][2]; int step_h0 = (input->blc_size[IS_P8x8(currMB) ? 4 : currMB->mb_type][0] >> 2)`.
Here, the program chooses `currMB->mb_type=10` as index. But since it is `10`, it overflows `input->blc_size[8]` and reads some garbage from adjacent fields.
Only GCC-MPX with bounds-narrowing detects this bug.
Interestingly, ICC-MPX does not detect this bug.
Though it also has `10`, but the bounds it checks against are huge for `blc_size[]` and no error is detected.
So there is some slight difference in how ICC and GCC narrowed bounds here---most probably due to different memory layouts.

* **h264ref: ICC compiler bug, wontfix**.
The bug triggers only on ICC-MPX with bounds-narrowing and in peculiar corner-cases (some ICC autovectorization optimization clashes with MPX instrumentation).
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700675).

* **milc: ICC compiler bug, wontfix**.
The bug triggers only on ICC-MPX (with and without bounds-narrowing) and in peculiar corner-cases (some ICC autovectorization optimization clashes with MPX instrumentation).
In `su3_proj.c:su3_projector`, the bound is narrowed to 16 bytes: `bndmk  bnd0,[rsi+0xf]`. Later, the argument `b` is compared against this bound. Since ICC employs autovectorization, `rsi` loads more than 16 bytes (actually, 32 bytes), and the upper-bound check `bndcu  bnd0,[rsi+0x1f]` fails.
Interesting and unfortunate, there was **no such bug** in ICC 16.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700675).

* **omnetpp: bug fix**.
There was a lazy memory copy of a structure, which failed under AddressSanitizer and ICC-MPX: `memcpy( &ss, &val.ss, Max(sizeof(ss), sizeof(func)) )`.
The fix: replaced it with an explicit copy of the structure fields: `ss.sht = val.ss.sht; memcpy( &ss.str, &val.ss.str, sizeof(ss.str));`.

* **perlbench: buffer overflow fix**.
In `perlio.c:PerlIO_find_layer`, there was a wrong string comparison: `if (memEQ(f->name, name, len) && f->name[len] == 0)`, and if `f->name` is shorter than `len`, there was an out-of-bounds read.
The fix: replaced with `if (!strcmp(f->name, name))`.
(Also fixed in AddressSanitizer patch.)

* **perlbench: flexible array fix**.
There was a flexible array in `hv.h:26` in struct `hek` declared as `hek_key[1]`.
Later it was correctly malloced with greater size, but ICC-MPX and GCC-MPX with bounds-narrowing (both) always assume the size of `1`.
The fix: declaring array with zero size which MPX treats as boundless: `hek_key[0]`.

* **perlbench: buffer overflow, wontfix**.
Out-of-bounds write in `regcomp.c:S_reg_node`: the `pRExC_state->emit->flags` (of type `regnode`) is not the correct address, and `#BR` is triggered.
This bug was (found by others in 2002)[http://www.nntp.perl.org/group/perl.perl5.porters/2002/04/msg57759.html and http://www.gossamer-threads.com/lists/perl/porters/149934].
The bug was found only by GCC-MPX with bounds-narrowing.
ICC-MPX does not detect this---most probably because ICC has another memory layout which hides the bug.
Wontfix: others did not fix the bug but simply used a newer version of perl (where bug disappeared).

* **soplex: numerous memory model violations, wontfix**.
Soplex has peculiar memory-management feature that *directly moves* objects from one referent region to another.
This breaks memory-management assumptions of bounds checking completely.
The crux: `reMax` function in `dataset.h:458` does the following: (1) memorize the previous referent address of the object, (2) allocate new memory region using `realloc`, and (3) calculate the difference (delta) between the new memory region and the previous one.
This delta is later used in `move` of a list in `islist.h:354` to *genuinely change* pointer-to-object from one address to another, without any respect towards pointer bounds (which is associated with the previous memory region).
This leads to false positive and breaks all MPX versions.

* **xalancbmk: memory model violation, wontfix**.
A bounds check in `DOMParentNode.cpp:insertBefore` assumes a subobject, but the program performs a *container*-style (see (Beyond PDP-11)[http://dl.acm.org/citation.cfm?id=2694367]) subtraction: `base - 0x8`.
This forces the lower-bound check to trigger `#BR` exception.
Only GCC-MPX and ICC-MPX with bounds-narrowing (both) have this issue.

* **xalancbmk: ICC compiler bug, wontfix**.
The bug triggers on ICC-MPX without bounds-narrowing and in peculiar corner-cases (ICC-MPX pass incorrectly passes bounds through indirect call).
In `egularExpression.cpp:matches`, the variable `pMatch` incorrectly gets NULL bounds, which makes MPX later crash.
[Bug report](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700550).

* **xalancbmk: flexible array fix**.
There was a flexible array in `DOMStringPool.cpp:83` in struct `DOMStringPoolEntry` declared as `fString[1]`.
Later it was correctly malloced with greater size, but ICC-MPX and GCC-MPX with bounds-narrowing (both) always assume the size of `1`.
The fix: declaring array with zero size which MPX treats as boundless: `fString[0]`.

* **xalancbmk: GCC compiler bug, wontfix**.
Fatal internal GCC compiler error under GCC-MPX with writes-only: `XercesDefs.hpp:456:39: internal compiler error: in ipa_propagate_frequency, at ipa-profile.c:403`.

* **mcf: memory model violation, wontfix (only for test input)**.
`mcf`, just like `soplex`, has a peculiar memory-management feature that *directly moves* objects from one referent region to another.
This breaks memory-management assumptions of bounds checking completely.
`implicit.c:resize_prob` function does the following: (1) memorize the previous referent address of the object, (2) allocate new memory region using `realloc`, and (3) calculate the difference (delta) between the new memory region and the previous one.
This delta is used below in the same function (`implicit.c:69`) to *genuinely change* pointer-to-object from one address to another, without any respect towards pointer bounds (which is associated with the previous memory region). This leads to false-positive `#BR` exceptions.
*Note*: this `realloc` behavior triggers only in special cases; it does not trigger on `native` inputs, but triggers on `test`.


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->
