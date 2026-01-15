BGGP6 writeup
=============

This is my writeup for BGGP #6 (https://binary.golf/), an annual small file competition.

Palindromic Polyglot Replicator Crasher Downloader
--------------------------------------------------

See [here](allinone/README.md) for the writeup for this entry

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

It is well-known that the lower limit for a 32bit i386 ELF file is 45 byte (see [1] above). The goal for this entry was - how much BGGP can I squeeze into 45 bytes?
Just doing an exit(6) would be a trivial change of Brian Raiter's original program, but that's not very ...original.

Every other challenge is too big - the smallest I got (without too much cheating) is 71 bytes for BGGP5 (I hope I can find enough time to do a writeup for that one too).

So, what are we left with? We can print "6" instead of just returning it. A first version, printing "6" and exitting was relatively easy to create (see print6/print6b for source):

``` assembler
 d439019:       90                      nop
 d43901a:       43                      inc    ebx
 d43901b:       0d 04 00 00 00          or     eax,0x4
 d439020:       42                      inc    edx
 d439021:       6a 36                   push   0x36
 d439023:       89 e1                   mov    ecx,esp
 d439025:       cd 80                   int    0x80
 d439027:       4b                      dec    ebx
 d439028:       cd 80                   int    0x80
 d43902a:       20 00                   and    BYTE PTR [eax],al
 d43902c:       01                      .byte 0x1
```
(base64: f0VMRgEAAAA2CgAANppDDQIAAwAZkEMNGZBDDQQAAABCajaJ4c2AS82AIAAB)

We set STDOUT as part of the address of the program, and setting eax == 4 reuses the e_phoff field of the ELF. Pushing '6' on the stack is two bytes with `push 0x36`.
And fortunately for us, printing 1 byte will leave 1 in eax, which just happens to be the syscall number for exit. With just one more byte for the `dec ebx` (which we still have to spare) we can get a clean exit for almost nothing.

Still, there's no newline, which feels a bit meh. Can we do better? At first it looks bleak... pushing anything bigger than 128 is suddenly 5 bytes. Moving a 32-bit address into a register is also 5 bytes. And there's not really any room for .data section left... PHDR begins at offset 4, so no using the header for any strings. VirtAddr is fixed. PhysAddr is used for more of the ELF header. FileSiz and MemSiz are also pretty much fixed. The Align field is already code.

The only thing left is the Offset field of the PHDR. But wait - that' also not really useable, as our text segment is not at an offset. And the smallest offset for text segments is 0x1000 bytes (one page), which would make our program way too big.

But wait... the kernel somehow allows us to set any value up to 0xfff, and seemingly rounds it down to 0. At least, it's that way if you then also add that offset value to the VirtAddr. And "6\n" just happens to be 0xa36. Thank you whoever defined ASCII newline as <= 0xf.

If you look at the program headers of my entry (with a patched readelf to not croak about the size and seemingly wrong header bytes):
```
Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  LOAD           0x000a36 0x6804ba36 0x00030002 0x6804b019 0x6804b019 R   0x4b008b9
```
You can see offset being 0xa36, and VirtAddr being page_offset+offset.


The program itself:
```
┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
│00000000│ 7f 45 4c 46 01 00 00 00 ┊ 36 0a 00 00 36 ba 04 68 │•ELF•000┊6_006×•h│
│00000010│ 02 00 03 00 19 b0 04 68 ┊ 19 b0 04 68 04 00 00 00 │•0•0•×•h┊•×•h•000│
│00000020│ b9 08 b0 04 68 5a cd 80 ┊ eb fe 20 00 01          │×•×•hZ××┊×× 0•   │
└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
```
``` assembler
6804b019:       b0 04                   mov    al,0x4
6804b01b:       68 04 00 00 00          push   0x4
6804b020:       b9 08 b0 04 68          mov    ecx,0x6804b008
6804b025:       5a                      pop    edx
6804b026:       cd 80                   int    0x80
6804b028:       eb fe                   jmp    0x6804b028
6804b02a:       20 00                   and    BYTE PTR [eax],al
6804b02c:       01                      .byte 0x1
```
(source and binary available in print6 folder)

We set eax to SYS_write in the first two bytes, and then use e_phoff to push 4 on the stack. 5 whole bytes are then used to set ecx to the phdr offset field. There was no room to set edx to exactly 2, so e_phoff on the stack is used to set it to 4 - this will result in two extra null bytes being printed, but this is not visible on any terminal.

But wait once more... the file descriptor never gets set, and there's no exit()!

In fact, ebx stays at 0, which is STDIN. But the text still gets printed? The reason for this is that terminals are opened in read/write mode, and without any shell redirection, STDIN/STDOUT/STDERR just get dup()'ed, and are in fact the same file descriptor.

And about that exit... ~~there was just no space left~~. I mean... I wanted to make a statement about enjoying the number 6 for as long as you want, similar to John Cage's seminal work *4'33"*. But... longer if you wish so.

It was clear that there was no room for a proper exit() syscall, so I looked for some shorter alternatives (all 1 or 2 bytes):
``` assembler
int3                   ; trap
aam    0               ; float exception
int    0x80            ; double print, segv
xchg   eax, esp        ; bus error
ud2                    ; illegal ins
jmp    $               ; endless loop
```
In the end I chose the endless loop, as this does not lead the executable to exit with an error code per se. The impatient user might create an error by pressing Ctrl+C, but that is on them, not on the program.




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
* use `/proc/<PPID>/cwd` to find the parents working directory
* There's no easy way to obtain what the *filename* of the package currently being installed is. To get that, we have to parse the command line arguments of the parent, via `/proc/<PPID>/cmdline`. But the arguments are null-delimited, which shell scripts famously are really bad at.
* Now we can go in the parents working directory, and copy the file from commandline argument nr.3 (first two being "dpkg" and "-i") to a file called "6".

So, how much code do we need for that? Turns out, not that much:
``` shell
cd /*/$PPID
set `tr '\0' ' '<cmdline`
cd cwd
cp $3 6
`
```
* `cd /*/$PPID` changes directory to the /proc/<PPID>/ folder. The star works because there aren't many purely numerical directories in the second level under the root folder, and it saves some precious bytes.
* `set \`tr '\0' ' '<cmdline\`` is doing quite a lot at once:
  * `tr '\0' ' '<cmdline`: this pipes `cmdline` into tr, replacing binary zeroes with whitespaces
  * `set -- $foo` is used for splitting a variable along the characters specified in `$IFS` (which defaults to space/newline/tab). But where did the `--` go? Turns out it's not needed if there's no way the input string could be mistaken for a shell option (setting shell options is the primary use of set, e.g. `set -ue`). It's a bit unclear if this was a planned or unplanned feature, but I gladly take the bytes saved.
* The `cd` and `cp` lines are pretty self-evident: Go to the parents working directory, and copy the parents third argument to "6". Please note that this works with both absolute and relative paths to the deb file
* The last line merely exits the script with an error message, due to it being a syntax error

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



