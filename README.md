BGGP6 writeup
=============

ELF/sh polyglot
---------------

This was the first entry I ever submitted to the BGGP, and the first entry overall to BGGP6.
For my first entry, I decided to submit an ELF and shell script polyglot.

Making small 32-bit ELF executables for Linux/386 has been extensively discussed by Brian Raiter[1],
so I won't rehash it here.

But using a
```
ELF                                             cpu/type                start       phdr_off                                  phdrsiz/cnt
7f 45 4c 46 .. .. .. .. .. .. .. .. .. .. .. .. 02 00 03 00 .. .. .. .. 54 11 01 00 34 00 00 00 .. .. .. .. .. .. .. .. .. .. 20 00 03 00 .. ..
                                                                                                01 00 00 00 ab 0c 00 00 ab dc ef gh .. .. .. .. ij kl mn op qr st uv wx .7 .. .. .. .. ..
                                                                                                p_type      offset      vaddr       paddr       filesz      memsz       flg         align
```

[1] https://www.muppetlabs.com/~breadbox/software/tiny/

ELF print6
----------

Other entries?
--------------
* downloader
  * code: where
  * 45b "version"?
* 45b print "6"
  * code: uploaded
  * writeup: nope
* palindromic polyglot replicator crasher downloader (a.k.a. the big one)
  * github issues for radare2:
    https://github.com/radareorg/radare2/pull/24730
    https://github.com/radareorg/radare2-testbins/pull/112
    
* replicator crasher downloader written in my own Forth dialect
* world's smallest ELF palindrome
* world's smallest DEB packages
* perl crasher
