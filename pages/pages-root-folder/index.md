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


<div class="row">
<div class="large-6 large-push-3 columns" markdown="0">
    
    <h1 id="intel-mpx-explained" style="text-align:center; margin-bottom: 2pt;">Intel MPX Explained</h1>
    <div style="text-align:center; color: #333;">An empirical study of Intel MPX and software-based bounds checking approaches</div>
    <br/>

</div><!-- /.large-6.columns -->
</div><!-- /.row 1 -->


<!--<div class="row">
  
    <div class="large-2 large-push-3 columns" markdown="0" style="text-align:center;">
        <a href="https://arxiv.org/pdf/1702.00719v1.pdf">
            <img class="t0" width="20%" src="/images/pdf-icon.png" alt="Technical Report">
            <div style="text-align:center; margin: 0 0 0 0; font-size: 0.8em;">Technical Report</div>
        </a>
    </div>
    
    <div class="large-2 large-push-3 columns" markdown="0" style="text-align:center;">
        <a href="https://arxiv.org/pdf/1702.00719v1.pdf">
            <img class="t0" width="20%" src="/images/bibtex.jpg" alt="BibTex">
            <div style="text-align:center; margin: 0 0 0 0; font-size: 0.8em;">BibTex</div>
        </a>
    </div>
    
    <div class="large-2 large-pull-3 columns" markdown="0" style="text-align:center;">
        <a href="https://github.com/OleksiiOleksenko/intel_mpx_explained">
            <img class="t0" width="20%" src="/images/github.png" alt="Source Code">
            <div style="text-align:center; margin: 0 0 0 0; font-size: 0.8em;">Source Code</div>
        </a>
    </div>

</div>-->


<div class="row">
<div class="medium-12 columns" markdown="1">

#### Corresponding publications:

<!--* [Our ATC'17 submission "Intel MPX explained"]() _(not yet published)_-->
* [Technical Report "Intel MPX Explained: An Empirical Study of Intel MPX and Software-based Bounds Checking Approaches"](https://arxiv.org/abs/1702.00719)
<a href="https://arxiv.org/pdf/1702.00719v1.pdf"><img class="t0" width="3%" src="/images/pdf-icon.png" alt="Technical Report"></a>
<a href="/code/tech_rep.bib"><img class="t0" width="3%" src="/images/bibtex.jpg" alt="BibTex"></a>
<a href="https://github.com/OleksiiOleksenko/intel_mpx_explained"><img class="t0" width="3%" src="/images/github.png" alt="Source Code"></a>

----

<h3 style="text-align:center; margin-top: 0; margin-bottom: 1em; font-size: 1.8em;">Results of the evaluation</h3>

</div><!-- /.medium-6.columns -->
</div><!-- /.row 2 -->

<div class="row">
<div class="large-4 columns" markdown="0">
    
    <div style="text-align:center;">
        <a href="/performance/">
            <img class="t0" width="60%" src="/images/plot-icon.jpg" alt="Performance Evaluation">
            <h4 style="text-align:center; margin: 0 0 0 0;">Performance</h4>
        </a>
    </div>
    
</div><!-- /.large-4.columns -->

<div class="large-4 columns" markdown="0">
    
    <div style="text-align:center;">
        <a href="/security/">
            <img class="t0" width="60%" src="/images/security-icon.png" alt="Secutiry Evaluation">
            <h4 style="text-align:center; margin: 0 0 0 0;">Security</h4>
        </a>
    </div>
    
</div><!-- /.large-4.columns -->
<div class="large-4 columns" markdown="0">
    
    <div style="text-align:center;">
        <a href="/usability/">
            <img class="t0" width="85%" src="/images/results_table.jpg" alt="Usability Evaluation">
            <h4 style="text-align:center; margin: 0 0 0 0;">Usability</h4>
        </a>
    </div>
  
</div><!-- /.large-4.columns -->
</div><!-- /.row 3 -->

<div class="row">
<div class="medium-12 columns" markdown="1">

<br/>

----

<h2 style="text-align:center; margin-top: 0; margin-bottom: 1em; font-size: 1.8em;">Looking for more information?</h2>


</div><!-- /.medium-12.columns -->
</div><!-- /.row 4 -->


<div class="row">
<div class="large-5 large-push-1 columns" markdown="1" style="padding-left: 0">
    
[Brief overview of our study](/overview)

[Complete description of Intel MPX](/design/)

[Isolated measurements of different aspects of Intel MPX](/microbenchmarks/) 
    
</div><!-- /.large-6.columns -->

<div class="large-5 large-pull-1 columns" markdown="1" style="text-align: right">
    
[Tests on real-world case studies](/case-studies/)

[Experimental setup](/methodology/)

</div><!-- /.large-6.columns -->
</div><!-- /.row 5 -->


