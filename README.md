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

`dpkg` starts several subprocesses [XXX preinst script], which all run with `/` as the working directory, so replicating the deb file to your current working directory should be impossible, right?
Well, not completely. But to do it, we would have to do the following steps:
* get the PID of the current shellscripts parent (getppid() syscall)
* use /proc/<PPID>/cwd to find the parents working directory
* There's no easy way to obtain what the *filename* of the package currently being installed is. To get that, we have to parse the command line arguments of the parent, via /proc/<PPID>/cmdline. But the arguments are null-delimited, which shell scripts famously are really bad at.
* Now we can go in the parents working directory, and copy the file from commandline argument nr.3 (first two being "dpkg" and "-i") to a file called "6".

So, how much code do we need for that? Turns out, not that much:
``` shell
cd /*/$PPID
set `tr '\0' ' '<cmdline`
cd cwd
cp $3 6
`
```

* perl crasher

You know a language is dead when they don't even bother to fix a segfault anymore. Welcome to the writeup for my BGGP3 perl crasher.

## Usage 
`perl crash.pl`
Should work in any perl version of the last twenty years or so.

## Explanation

The perl script itself is really small:
``` perl
DESTROY{bless[]}bless[]
```
But what does it do? `bless` 'blesses' a data structure, to turn it into some low-level OOP construct (don't ask. Just... don't). So, `bless []` creates a new blessed list from a list reference. And `DESTROY` defines a destructor for objects (and `bless[]` is just saving one of those annoying whitespaces. Who needs those? With Perl you can save so much time by omitting random whitespaces!).

So, the program defines a destructor which constructs a new object. And then we create a single object. Run it, and you'll get a stack overflow in a few milliseconds. Unfortunately it doesn't pass as a valid BGGP6 program, due to a lack of outputting '6'. To fix that:
``` perl
DESTROY{bless[]}die$=,bless[]
```

Or, more readable, after running through `Deparse`:
``` perl
sub DESTROY {
	    bless([]);
}
die($=, bless([]));
```

Only addition is `die$=,`. `die` is for throwing an error, and once again we cleverly saved some unneeded whitespaces by writing `die$=`. And `$=` is... a special Perl variable that happens to be set to 60 by default. So nothing more than a bit of obfuscation. This combination of `die` and `bless` happens to print an error message before having a stack overflow, while other variants don't.

Output should be:
```
$ perl crash.pl
60main=ARRAY(0x5555558ff4b8) at crash.pl line 1.
Segmentation fault (core dumped)
```

The bug is known https://github.com/Perl/perl5/issues/11493, but nobody is bothering to fix it.

Perl is like smoking. Some of us can't stop using it for quick&dirty hacks, but people not previously addicted to it should not start the bad habit. And coding any large applications in it was never a good idea in the first place.



