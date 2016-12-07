---
layout: page-fullwidth
show_meta: false
title: "Security Evaluation"
subheadline:
teaser:
header: no
permalink: "/security/"
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

## RIPE testbed  {#ripe}

We evaluated all approaches against the RIPE security testbed.[^ripe] RIPE is a synthesized C program that tries to attack itself in a number of ways, by overflowing a buffer allocated on the stack, heap, or in data or BSS segments. RIPE can imitate up to 850 attacks, including shellcode, return-into-libc, and return-oriented programming.

To evaluate security of approaches, we disabled all other security features:

* Linux ASLR was disabled via `sudo bash -c 'echo 0 > /proc/sys/kernel/randomize_va_space'`
* All compiler optimizations were disabled via `-O0`
* Compiler-inserted stack canaries were disabled via `-fno-stack-protector`
* Compiler-enforced fortify-source was disabled via `-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0`
* Executable stack was enabled via compiler flag `-Wl,-z,execstack`

Even under these relaxed security flags all compilers were susceptible only to a small number of attacks. Under native GCC, only *64* attacks survived, under ICC -- *34*, and under Clang -- *38*.

### Results

| Approach                   | Working attacks |
|:---------------------------|----------------:|
| MPX (GCC) default*         | **41/64** (all memcpy and intra-object overflows) |
| MPX (GCC)                  | **0/64** (no working attacks) |
| MPX (GCC) no narrow bounds | **14/64** (all intra-object overflows)   |
|----
| MPX (ICC)                  | **0/34** (no working attacks) |
| MPX (ICC) no narrow bounds | **14/34** (all intra-object overflows) |
|----
| AddressSanitizer           | **12/64** (all intra-object overflows) |
| SoftBound                  | **14/38** (all intra-object overflows) |
| SafeCode                   | **14/38** (all intra-object overflows) |

{% include alert text='**Note 1**. In Col. 2, **41/64** means that 64 attacks were successful in native GCC version, and 41 attacks remained in MPX version.' %}
{% include alert text='**Note 2**. The "default" version of GCC-MPX means without `-fchkp-first-field-has-own-bounds` and with `BNDPRESERVE=0`, see below.' %}

Surprisingly, a default GCC-MPX version showed very poor results, with 41 attacks (or 64% of all possible attacks) succeeding. As it turned out, the default GCC-MPX flags are sub-optimal. First, we found a [bug](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=78631) in the `memcpy` wrapper which forced bounds registers to be nullified, so the bounds checks on `memcpy` were rendered useless. This bug disappears if `BNDPRESERVE` is manually set to one. Second, the MPX pass in GCC does not narrow bounds for the first field of a struct by default, in contrast to ICC which is more strict. To catch intra-object overflows happening in the first field of structs one needs to pass the `-fchkp-first-field-has-own-bounds` flag to GCC. When we enabled these two flags, all attacks were prevented; all next rows in the table were tested with these flags.

Other results are expected. MPX versions without narrowing of bounds overlook 14 intra-object overflow attacks, where a vulnerable buffer and a victim object live in the same struct. The same attacks are overlooked by AddressSanitizer, SoftBound, and SafeCode. Interestingly, AddressSanitizer has 12 working attacks, i.e., two attacks less than other approaches. Though we did not inspect this in detail, AddressSanitizer was able to prevent two shellcode intra-object attacks on the heap.

We performed the same experiment with *only-writes* versions of these approaches, and the results were exactly the same. This is explained by the fact that RIPE constructs only control-flow hijacking attacks and not information leaks (which could escape only-writes protection).


### More details

Below are the logs which show which attacks worked under each approach.

* Native versions:
  * [GCC]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_native.txt)
  * [ICC]({{ site.url }}{{ site.baseurl }}/code/ripe/icc_native.txt)
  * [Clang]({{ site.url }}{{ site.baseurl }}/code/ripe/clang_native.txt)
* MPX versions:
  * [GCC default]({{ site.url }}{{ site.baseurl }}/code/ripe/badgcc_mpx.txt)
  * [GCC]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_mpx.txt)
  * [GCC only-writes]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_mpx_only_write.txt)
  * [GCC no narrow bounds]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_mpx_no_narrow_bounds.txt)
  * [GCC no narrow bounds only-writes]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_mpx_no_narrow_bounds_only_write.txt)
  * [ICC]({{ site.url }}{{ site.baseurl }}/code/ripe/icc_mpx.txt)
  * [ICC only-writes]({{ site.url }}{{ site.baseurl }}/code/ripe/icc_mpx_only_write.txt)
  * [ICC no narrow bounds]({{ site.url }}{{ site.baseurl }}/code/ripe/icc_mpx_no_narrow_bounds.txt)
  * [ICC no narrow bounds only-writes]({{ site.url }}{{ site.baseurl }}/code/ripe/icc_mpx_no_narrow_bounds_only_write.txt)
* AddressSanitizer versions:
  * [full]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_asan.txt)
  * [only-writes]({{ site.url }}{{ site.baseurl }}/code/ripe/gcc_asan_only_write.txt)
* [SoftBound]({{ site.url }}{{ site.baseurl }}/code/ripe/clang_softbound.txt)
* [SafeCode]({{ site.url }}{{ site.baseurl }}/code/ripe/clang_safecode.txt)


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->

[^ripe]: John Wilander and Nick Nikiforakis and Yves Younan and Mariam Kamkar and Wouter Joosen. RIPE: Runtime Intrusion Prevention Evaluator. In ACSAC'2011.