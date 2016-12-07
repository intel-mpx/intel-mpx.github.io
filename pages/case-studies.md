---
layout: page-fullwidth
show_meta: false
title: "Case Studies"
subheadline:
teaser:
header: no
permalink: "/case-studies/"
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

**Testbed**: two identical machines, one as client and one as server.
The characteristics of machines and the network can be found in the [Methodology page]({{ site.url }}{{ site.baseurl }}/methodology).

## Apache web server  {#apache}

* **Version**: 2.4.18
* **Configuration**: default (MPM event model: hybrid multi-process multi-threaded)
* **Dependencies[^deps]**:
  * OpenSSL 1.0.1f (susceptible to the Heartbleed bug)
  * apr-1.5.2
  * apr-util-1.5.4
  * PCRE 8.38
* **Workload**:
  * ab benchmark
  * with keepalive connections
  * fetching of a 2.3K static web-page
  * using HTTP get

### Performance
<img class="t20" width="75%" src="{{ site.urlimg }}apache_tput.jpg" alt="Apache throughput-latency plot">

Additional statistics[^stats]:

|                        | Native | MPX  | ASan |
|:-----------------------|-------:|-----:|-----:|
| Throughput (MBit/s)    | 865    | 850  | 865  |
| CPU utilization (%)    | 480    | 510  | 500  |
| Instructions/cycle     | 0.6    | 0.63 | 0.74 |
|----
| Resident Set Size (MB) | 9.4    | 120  | 33   |
| Minor page faults (K)  | 2.6    | 4.1  | 9.6  |
|----
| L1 cache misses (%)    | 12     | 14   | 12   |
| LLC cache misses (%)   | 1.2    | **_8_**| 1.6  |
|=====
| (network is a bottleneck in all cases)

**Performance Summary**: GCC-MPX, ICC-MPX, and AddressSanitizer all show minimal overheads, achieving 95.3%, 95.7%, and 97.5% of native throughput. Overhead in latency did not exceed 5%. Such good performance is explained by the fact that our experiment was limited by the network and not CPU or memory.

**Memory Summary**: AddressSanitizer exhibits an expected 3.5X overhead. In contrast, MPX variants have dramatic 12.8X increase in memory consumption. This is explained by the fact that Apache allocates an additional 1MB of pointer-heavy data per each client, which in turn leads to the allocation of many Bounds Tables.

### Security

* **Bug**: Heartbleed, [official web-site](http://heartbleed.com/) and [detailed explanation](http://www.theregister.co.uk/2014/04/09/heartbleed_explained/)
* **Exploit script**: [by Jared Stafford and Travis Lee](https://github.com/OleksiiOleksenko/mpx_evaluation/blob/dev/experiments/exp_apache_security/heartbleed.py)

**Results**:

|                 | Native | MPX  | ASan |
|:----------------|-------:|-----:|-----:|
| Bug detected    | no     | yes  | yes  |

**Summary**: AddressSanitizer and GCC-MPX detect Heartbleed without any problems.

{% include alert text='**Note**. The actual situation with Heartbleed is more contrived. OpenSSL uses its own memory manager which partially bypasses the wrappers around malloc and mmap. Thus, in reality memory-safety approaches find Heartbleed only if the length parameter is greater than 32KB (the granularity at which OpenSSL allocates chunks of memory for its internal allocator). [More info](http://www.tedunangst.com/flak/post/heartbleed-vs-mallocconf).' %}


### Usability

**Issue 1**: While testing against Heartbleed, we discovered that ICC-MPX suffers from a run-time Intel compiler bug 5 in the x509_cb OpenSSL function, leading to a crash of Apache. This bug triggered only on HTTPS connections, thus allowing us to still run performance experiments on ICC-MPX. [See bug here](https://software.intel.com/en-us/forums/intel-c-compiler/topic/700550).


<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Nginx web server {#nginx}

* **Version**: 1.4.0 (susceptible to [this bug](http://cve.mitre.org/cgi-bin/cvename.cgi?name=cve-2013-2028))
* **Configuration**: worker_processes = auto (1 process per core)
* **Dependencies[^deps]**: OpenSSL 1.0.1f
* **Workload**:
  * ab benchmark
  * with keepalive connections
  * fetching of a 2.3K static web-page
  * using HTTP get

### Performance
<img class="t20" width="75%" src="{{ site.urlimg }}nginx_tput.jpg" alt="Nginx throughput-latency plot">

Additional statistics[^stats]:

|                        | Native | MPX  | ASan |
|:-----------------------|-------:|-----:|-----:|
| Throughput (MBit/s)    | 850    | 840  | 840  |
| CPU utilization (%)    | 225    | 265  | 300 |
| Instructions/cycle     | 0.81   | 0.82 | 0.81 |
|----
| Resident Set Size (MB) | 4.3    | 18   | **_380_**  |
| Minor page faults (K)  | 2.0    | 4.5  | **_1250_** |
|----
| L1 cache misses (%)    | 9      | 10   | 10   |
| LLC cache misses (%)   | 0.7    | 0.7  | **_9_**  |
|=====
| (network is a bottleneck in all cases)

**Performance Summary**: AddressSanitizer reaches 95% of native throughput, while GCC-MPX and ICC-MPX lag behind with 86% and 89.5% respectively. Similar to Apache, this experiment was network-bound, with CPU usage of 225% for native, 265% for MPX, and 300% for AddressSanitizer. (CPU usage numbers prove that HW-assisted approaches impose less CPU overheads.)

**Memory Summary**: MPX variants have a reasonable 4.2X memory overhead, but AddressSanitizer eats up 88X more memory (it also has 625X more page faults and 13% more LLC cache misses).

{% include alert text='Why MPX is slower than AddressSanitizer if their memory characteristics indicate otherwise? The reason for the horrifying AddressSanitizer numbers is its quarantine feature -- AddressSanitizer employs a special memory management system which avoids re-allocating the same memory region for new objects, thus decreasing the probability of temporal bugs such as use-after-free. Due to quarantine, AddressSanitizer experiences huge memory blow-up. When we disabled this feature, AddressSanitizer used only 24MB of memory.' %}


### Security

* **Bug**: Stack buffer overflow, [CVE-2013-2028](http://cve.mitre.org/cgi-bin/cvename.cgi?name=cve-2013-2028) and [detailed explanation](http://www.vnsecurity.net/research/2013/05/21/analysis-of-nginx-cve-2013-2028.html)
* **Exploit script**: [This Ruby script](https://github.com/OleksiiOleksenko/mpx_evaluation/blob/dev/experiments/exp_nginx_security/CVE-2013-2028.rb)

{% include alert text='**Note**. To exploit the bug, one needs to `apt-get install gem rubygems ruby-dev sqlite3 libsqlite3-dev` and `gem install ronin` in Ubuntu.' %}

**Results**:

|                 | Native | MPX  | ASan |
|:----------------|-------:|-----:|-----:|
| Bug detected    | no     | **no**  | yes   |

**Summary**: AddressSanitizer detects this bug, but both versions of MPX *do not*. The root cause is the run-time wrapper library: AddressSanitizer wraps all C library  functions including `recv`, and the wrapper -- not the Nginx instrumented code -- detects the stack buffer overflow. In case of both GCC-MPX and ICC-MPX, only the most widely used functions are wrapped and bounds-checked. That is why when `recv` is called, the overflow happens in the unprotected C library function and goes undetected by MPX.


### Usability

**Issue 1**: To successfully run Nginx under GCC-MPX with narrowing of bounds, we had to manually fix a variable-length array `name[1]` in the `ngx_hash_elt_t` struct to
`name[0]`.

**Issue 2**: ICC-MPX first crashed with a false positive in `ngx_http_merge_locations` function. The reason for this bug was a cast from a smaller type, which rendered the bounds too narrow for the new, larger type. Note that GCC-MPX did not experience the same problem because it enforces the first struct’s field to inherit the bounds of the whole object by default -- in contrast to ICC-MPX which takes a more rigorous stance. For our evaluation, we used the version of ICC-MPX with narrowing of bounds disabled.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }


## Memcached caching system {#memcached}

* **Version**: 1.4.15 (susceptible to [this bug](http://www.cvedetails.com/cve/cve-2011-4971))
* **Configuration**: 8 threads (to keep all CPU cores busy)
* **Dependencies[^deps]**: libevent 2.0.22-stable
* **Workload**:
  * memaslap benchmark from libmemcached 1.0.16
  * with 10% ~400B sets and 90% ~1,700B gets

### Performance
<img class="t20" width="75%" src="{{ site.urlimg }}memcached_tput.jpg" alt="Memcached throughput-latency plot">

Additional statistics[^stats]:

|                        | Native | MPX  | ASan |
|:-----------------------|-------:|-----:|-----:|
| Throughput (MBit/s)    | 850    | 595  | 850  |
| CPU utilization (%)    | 300    | 320  | 345  |
| Instructions/cycle     | 0.85   | 0.7  | 0.92 |
|----
| Resident Set Size (MB) | 73     | **_352_**   | 95  |
| Minor page faults (K)  | 18     | **_86_**    | 26 |
|----
| L1 cache misses (%)    | 11     | 13   | 11   |
| LLC cache misses (%)   | 6      | **_13_**  | 6    |
|=====
| (network is a bottleneck only for native and ASan)

**Performance Summary**: AddressSanitizer performs on par with the native version. Both GCC-MPX and ICC-MPX achieved only 48−50% of maximum native throughput. In case of native and AddressSanitizer, performance of Memcached was limited by network. But it was not the case for MPX: Memcached exercised only 70% of the network bandwidth.

**Memory Summary**: While AddressSanitizer imposed only 30% memory overhead, both MPX variants used 350MB of memory (4.8X more than native). This huge memory overhead broke cache locality and resulted in 5.4X more page faults and 10−15% LLC misses, making MPX versions essentially memory-bound. (Indeed, the CPU utilization never exceeded 320%.)


### Security

* **Bug**: Buffer overflow due to signedness error, [CVE-2011-4971](http://www.cvedetails.com/cve/cve-2011-4971) and [detailed explanation](https://code.google.com/archive/p/memcached/issues/192)
* **Exploit script**: [Specially crafted TCP/IP packet](https://code.google.com/archive/p/memcached/issues/192)

**Results**:

|                 | Native | MPX  | ASan |
|:----------------|-------:|-----:|-----:|
| Bug detected    | no     | yes  | yes   |

**Summary**: All approaches detected buffer overflow in the affected function’s arguments and stopped the execution.


### Usability

We experienced no usability problems.

<small markdown="1">[Up to table of contents](#toc)</small>
{: .text-right }

</div><!-- /.medium-8.columns -->
</div><!-- /.row -->

[^stats]: All statistics are shown for the maximum achievable throughput and only for GCC versions; MPX showed similar results on GCC and ICC.

[^deps]: All dependencies (libraries) are built from source code and statically linked.