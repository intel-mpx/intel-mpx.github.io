# Logs for OS microbenchmarks

## Only allocate Bounds Tables

* Native version:

```
         331990568      cycles                                                        ( +-  0.34% )
          11924873      instructions:u                                                ( +-  0.00% )
         368572143      instructions:k                                                ( +-  0.11% )
          97066903      dTLB-loads                                                    ( +-  0.16% )
             11911      dTLB-load-misses          #    0.01% of all dTLB cache hits   ( +-  8.94% )
          52293345      dTLB-stores                                                   ( +-  0.00% )
            317002      dTLB-store-misses                                             ( +-  0.13% )

          86109958      L1-dcache-loads                                               ( +-  2.89% )  (42.34%)
           8907696      L1-dcache-load-misses     #   10.34% of all L1-dcache hits    ( +-  1.59% )  (58.03%)
          50208592      L1-dcache-stores                                              ( +-  1.27% )  (60.27%)
            202135      LLC-loads                                                     ( +-  4.36% )  (63.05%)
             98999      LLC-load-misses           #   48.98% of all LL-cache hits     ( +-  3.88% )  (61.42%)
           7606286      LLC-store-misses                                              ( +-  1.71% )  (26.74%)
           7785451      LLC-stores                                                    ( +-  4.39% )  (25.11%)

                 0      mpx:mpx_new_bounds_table

       0.094805894 seconds time elapsed                                          ( +-  0.19% )

    User time (seconds): 0.01
    System time (seconds): 0.07
    Percent of CPU this job got: 97%
    Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.09
    Average shared text size (kbytes): 0
    Average unshared data size (kbytes): 0
    Average stack size (kbytes): 0
    Average total size (kbytes): 0
    Maximum resident set size (kbytes): 360892
    Average resident set size (kbytes): 0
    Major (requiring I/O) page faults: 0
    Minor (reclaiming a frame) page faults: 89998
    Voluntary context switches: 1
    Involuntary context switches: 1
    Swaps: 0
    File system inputs: 0
    File system outputs: 0
    Socket messages sent: 0
    Socket messages received: 0
    Signals delivered: 0
    Page size (bytes): 4096
    Exit status: 0
```


* MPX version:

```
         748955083      cycles                                                        ( +-  0.50% )
          12886321      instructions:u                                                ( +-  0.00% )
         958417113      instructions:k                                                ( +-  0.38% )
         252435578      dTLB-loads                                                    ( +-  0.00% )
             49268      dTLB-load-misses          #    0.02% of all dTLB cache hits   ( +-  0.74% )
         101206131      dTLB-stores                                                   ( +-  0.01% )
            436380      dTLB-store-misses                                             ( +-  0.06% )

         241422911      L1-dcache-loads                                               ( +-  0.80% )  (43.33%)
          26787301      L1-dcache-load-misses     #   11.10% of all L1-dcache hits    ( +-  1.46% )  (58.34%)
         102794543      L1-dcache-stores                                              ( +-  1.12% )  (59.10%)
            658052      LLC-loads                                                     ( +- 12.23% )  (59.36%)
            296105      LLC-load-misses           #   45.00% of all LL-cache hits     ( +- 16.66% )  (58.64%)
          14015378      LLC-store-misses                                              ( +-  0.82% )  (27.46%)
          12541826      LLC-stores                                                    ( +-  1.52% )  (28.69%)

             30001      mpx:mpx_new_bounds_table                                      ( +-  0.00% )

       0.210824924 seconds time elapsed                                          ( +-  0.18% )

    User time (seconds): 0.02
    System time (seconds): 0.18
    Percent of CPU this job got: 98%
    Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.21
    Average shared text size (kbytes): 0
    Average unshared data size (kbytes): 0
    Average stack size (kbytes): 0
    Average total size (kbytes): 0
    Maximum resident set size (kbytes): 605660
    Average resident set size (kbytes): 0
    Major (requiring I/O) page faults: 0
    Minor (reclaiming a frame) page faults: 120124
    Voluntary context switches: 1
    Involuntary context switches: 2
    Swaps: 0
    File system inputs: 0
    File system outputs: 0
    Socket messages sent: 0
    Socket messages received: 0
    Signals delivered: 0
    Page size (bytes): 4096
    Exit status: 0

```



## Allocate and de-allocate Bounds Tables

(all unnecessary statistics were stripped off)

* Native version:

```
                 0      mpx:mpx_new_bounds_table
         442295765      cycles                                                        ( +-  0.41% )
          13667410      instructions:u                                                ( +-  0.00% )
         471676459      instructions:k                                                ( +-  0.29% )

       0.126743098 seconds time elapsed                                          ( +-  1.13% )
```


* MPX version:

```
             30001      mpx:mpx_new_bounds_table                                      ( +-  0.00% )
        1002757317      cycles                                                        ( +-  3.43% )
          15050452      instructions:u                                                ( +-  0.00% )
        1129961485      instructions:k                                                ( +-  0.72% )

       0.285584610 seconds time elapsed                                          ( +-  3.30% )
```
