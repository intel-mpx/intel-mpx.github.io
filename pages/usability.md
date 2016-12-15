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

The below figure highlights the usability of MPX, i.e., the number of MPX-protected programs that fail to compile correctly and/or need significant code modifications. Note that many programs can be easily fixed; we do not count them as broken. MPX security levels are based on our own classification and correspond to the stricter protection rules, where level 0 means unprotected native version and 6 -- the most secure MPX configuration.

In total, our evaluation covers 38 programs from the Phoenix, PARSEC, and SPEC benchmark suites.

<img class="t20" width="75%" src="{{ site.urlimg }}usability.jpg" alt="Number of MPX-broken programs">

As for other approaches, no programs broke under AddressSanitizer. For SafeCode, around 70% programs executed correctly (all Phoenix, half of PARSEC, and 3/4 of SPEC).  SoftBound -- being a prototype implementation -- showed poor results, with only simple programs surviving (all Phoenix, one PARSEC, and 6 SPEC). See details below.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Refined Usability Table  {#usabilitytable}

The below table shows all changes made to the programs under test as well as reasons why some programs break at compile- or run-time.

<img class="t20" width="75%" src="{{ site.urlimg }}results_table.jpg" alt="Refined usability table">


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->
