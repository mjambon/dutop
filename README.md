dutop - disk usage top
==

dutop is a command-line utility that scans the file system from a given
root path and reports any the file or directory that occupies
more than 5% of the space.

Example
--

```
$ dutop
d   5.2%               916,465 ./ocamldoc
d   5.8%             1,020,936 ./otherlibs/labltk
    5.9%             1,041,337 ./camlp4/boot/Camlp4.ml
    6.2%             1,099,386 ./boot/ocamlc
d  11.2%             1,978,514 ./testsuite/tests
d  11.3%             1,992,720 ./boot
d  11.5%             2,024,119 ./testsuite
d  12.0%             2,116,395 ./camlp4/boot
d  13.0%             2,304,653 ./otherlibs
d  22.0%             3,890,878 ./camlp4
d 100.0%            17,669,401 .
```

Installation
--

Requires a standard installation of OCaml.

```
$ make
$ make install  # Installation directory defaults to $HOME/bin.
```

PREFIX and BINDIR are supported, so if you want to install dutop in /usr/local,
just do:

```
$ sudo make PREFIX=/usr/local install
```

Uninstallation:

```
$ make uninstall
```

Author: Martin Jambon
