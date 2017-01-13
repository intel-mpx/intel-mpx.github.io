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

# Welcome to [intel-mpx.github.io](https://intel-mpx.github.io)!

This web-site supports our (future) ATC'17 submission---"Intel MPX explained", an evaluation of Intel Memory Protection Extension from three perspectives: **performance**, **security**, and **usability**. 
This web-site contains complete results of the evaluation as well as detailed explanation of the extension itself.

{% include alert text='Our work is still in progress. Please refrain from sharing and mentioning it.' %}

<div id="videoModal" class="reveal-modal large" data-reveal="">
  <div class="flex-video widescreen vimeo" style="display: block;">
    <iframe width="1280" height="720" src="https://www.youtube.com/embed/3b5zCFSmVvU" frameborder="0" allowfullscreen></iframe>
  </div>
  <a class="close-reveal-modal">&#215;</a>
</div>

### What is Intel MPX?

Intel has recently (in August 2015) released a new ISA extension---Memory Protection Extension (MPX).
The goal of it was to provide a highly efficient protection against memory errors and attacks. 
Here, by *memory errors*[^temporal] we understand errors that happen when a program reads from or writes to a different memory region than the one expected by the developer.
*A memory attack* is a different view on the same problem---it is a scenario in which an adversary gets access to the region of memory she is not allowed.

Although a few protection mechanisms had already existed before MPX, they were mainly implemented in software and caused significant slowdown of a protected program.
The aim of MPX was to add hardware assistance to memory protection and thus improve its performance. 

### What did we do in this work?

To our knowledge, there is no comprehensive evaluation of performance and security parameters of MPX, neither from academic community nor from Intel itself.
Therefore, the goal of this work was to perform an extensive and unbiased evaluation of MPX.

To fully explore pros and cons of the new extension, we had to put the results into perspective of existing software-based memory protection mechanisms.
We took three techniques that showcase main classes of memory protection:

* [Address Sanitizer](http://clang.llvm.org/docs/AddressSanitizer.html) represents _trip-wire_ (also, electric-fence) approaches. This class surrounds all objects with regions of marked memory (for example, with all "1"), so that any overflow will change the value in this region and it can be detected with a simple check.
* [SoftBound](https://www.cs.rutgers.edu/~santosh.nagarakatte/softbound/) is a pointer-based approach. Such approaches keep track of pointer bounds (the lowest and the highest allowed address) and check them on each memory write and read. 
* [SafeCode](http://safecode.cs.illinois.edu/) is an object-based approach. Its main idea is enforcing the intended referent, i.e., making sure that pointer manipulations do not change pointers' referred objects. 

In this work, we present results of these experiments and discuss applicability of MPX.
We also analyze the differences between two existing implementations of MPX in two major compilers---ICC and GCC---and how they influence the resulting performance.

## Results in short

TBD

## Looking for more details?

* Complete description of Intel MPX can be found in **[Design](/design)**
* Experimental setup can be found in **[Methodology](/methodology/)**
* Isolated measurements of different aspects of Intel MPX are presented in **[Microbenchmarks](/microbenchmarks/)**
* The evaluation itself consists of three parts:
    * **[Performance](/performance/)** page presents various run-time parameters
    * **[Security](/security/)** page evaluates security guaranties
    * **[Usability](/usability/)** page discusses various issues that appear when the considered protections are applied
* Results of tests on real-world applications are presented in **[Case Studies](/case-studies/)**


[^temporal]: The current version of Intel MPX protects only against "spatial" errors and attacks (described above). There are also "temporal" errors that appear when trying to use an object before it was created or after it was deleted. MPX does not yet provide a protection against them.