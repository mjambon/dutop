dutop - disk usage top
==

dutop is a command-line utility that scans the file system from a given
root path and reports any the file or directory that occupies
more than 5% of the space. It answers the question:

> Which single file or directory should I remove to reclaim significant
> storage space?

Example
--

Here's how to get a sense of what takes the most space in the `/usr`
directory:

```
$ dutop /usr
d   5.2%           429,055,696 /usr/local/lib/python3.5/dist-packages
d   5.2%           429,055,696 /usr/local/lib/python3.5
d   5.6%           461,789,323 /usr/lib/ghc
d   5.7%           473,685,763 /usr/share/doc
d   6.6%           549,563,745 /usr/bin
d   9.0%           743,990,153 /usr/local/lib
d  11.7%           972,273,271 /usr/local
d  16.9%         1,401,349,064 /usr/lib/x86_64-linux-gnu
d  27.7%         2,301,009,747 /usr/share
d  49.0%         4,070,197,838 /usr/lib
d 100.0%         8,309,946,131 /usr
```

The output is brief, since only any object representing at least 5% of
the total is shown. Compare that to `du /usr` which here produces
44,476 lines of output due to the large number of files. The closest
standard command would be `du -s`, which gives us the following:

```
$ du -s /usr/*
540568	/usr/bin
772	/usr/games
187364	/usr/include
4061168	/usr/lib
16880	/usr/lib32
17568	/usr/libx32
1110684	/usr/local         # lacks details
20	/usr/locale        # too small to be of interest
41052	/usr/sbin
2649668	/usr/share
370756	/usr/src
```

The granularity of `dutop` can be adjusted. For example, we can set it
to 3%:

```
$ dutop -m 0.03 /usr
d   3.0%           253,064,866 /usr/local/lib/node_modules
d   3.1%           260,450,536 /usr/lib/jvm
d   4.4%           369,531,237 /usr/share/doc/texlive-doc
d   5.2%           429,055,696 /usr/local/lib/python3.5/dist-packages
d   5.2%           429,055,696 /usr/local/lib/python3.5
d   5.6%           461,789,323 /usr/lib/ghc
d   5.7%           473,685,763 /usr/share/doc
d   6.6%           549,563,745 /usr/bin
d   9.0%           743,990,153 /usr/local/lib
d  11.7%           972,273,271 /usr/local
d  16.9%         1,401,349,064 /usr/lib/x86_64-linux-gnu
d  27.7%         2,301,009,747 /usr/share
d  49.0%         4,070,197,838 /usr/lib
d 100.0%         8,309,946,131 /usr
```

Installation
--

Requires a standard installation of OCaml and Dune.

```
$ make
$ make install
```

Uninstallation:

```
$ make uninstall
```

Author: Martin Jambon
