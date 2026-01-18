# perl crasher

You know a language is dead when they don't even bother to fix a segfault anymore. Welcome to the writeup for my BGGP3 perl crasher.

## Usage 
`perl crash.pl`

Should work in any perl version of the last ~~twenty~~ 25 years (tested with perl 5.6 from 2000, and the recent 5.42).

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

Or, more readable, after running through `B::Deparse`:
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

The bug is known (https://github.com/Perl/perl5/issues/11493), but nobody is bothering to fix it.

Perl is like smoking. Some of us can't stop using it for quick&dirty hacks, but people not previously addicted to it should not start the bad habit. And coding any large applications in it was never a good idea in the first place.


