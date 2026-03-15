BGGP6 writeup
=============

This is my writeup for BGGP #6 (https://binary.golf/), an annual small file competition.

Palindromic Polyglot Replicator Crasher Downloader
--------------------------------------------------

See [here](allinone/) for the writeup for this entry

ELF/sh polyglot
---------------

This was the first entry I ever submitted to the BGGP, and the first entry overall to BGGP6.
For my first entry, I decided to submit an ELF and shell script polyglot.

Making small 32-bit ELF executables for Linux/386 has been extensively discussed by Brian Raiter[1],
so I won't rehash it here.

I kinda forgot about the writeup for my first entry, so it'll be quite terse.

**_Please note: the rest of the ELF/sh polyglot writeup was written after the deadline_**

Using the well-known template by Brian Raiter leaves no room after the ELF magic numbers, complicating the inclusion of a shell script fragment.

That's why I ended up using the following template:
```
ELF                                             cpu/type                start       phdr_off                                  phdrsiz/cnt
7f 45 4c 46 .. .. .. .. .. .. .. .. .. .. .. .. 02 00 03 00 .. .. .. .. 54 11 01 00 34 00 00 00 .. .. .. .. .. .. .. .. .. .. 20 00 03 00 .. ..
                                                                                                01 00 00 00 ab 0c 00 00 ab dc ef gh .. .. .. .. ij kl mn op qr st uv wx .7 .. .. .. .. ..
                                                                                                p_type      offset      vaddr       paddr       filesz      memsz       flg         align
```
It was created in vim, and overlap for each position was tested by first moving the PHDR past the ELF header, and then successively deleting 3 characters at a time.

I created ELF/shell polyglots with much bigger payloads before, and for those I used tricks like starting a HERE-document right after the first four ELF header bytes, to safely hide 
null bytes and other non-executable stuff from the shell interpreter. But this was not necessary here, as the payload completely fits into the first few, unused, header bytes:

```
\x7fELF;exit 6
```

The ELF binary prints "6" and returns with exit code 2, fulfilling both the requirements from BGGP2 and BGGP6:

```
$ strace -rni ./bin
     0.000000 [  59] [000073ab39eeef3b] execve("./bin", ["./bin"], 0x7ffc1cdf2448 /* 24 vars */) = 0
     0.006834 [  59] [0020403e] [ Process PID=14392 runs in 32 bit mode. ]
     0.000030 [   4] [0020403e] write(1, "6", 16) = 1
     0.000142 [   1] [0020403e] exit(2) = ?
     0.000087 [   1] [????????] +++ exited with 2 +++
```

The shellscript returns with exit code 6, and prints a message about not finding a binary called ELF or similar (exact message depends on shell being used and locale):

```
$ dash -x ./bin
+ ELF
./bin: 1: ELF: not found
+ exit 6
```

So... success? Not quite: I originally submitted this as an ELF/*Bash* polyglot, but then found out that later versions of Bash specifically detect ELF files, and refuse to run
them. D'oh!

It used to be that Bash had simple heuristics to differentiate shell scripts from binary files. The first line of the 'script' (i.e. up to the first newline) must not contain any null bytes. But this changed in Bash 5.2, when the explicit check for ELF files was added [2].

[1] https://www.muppetlabs.com/~breadbox/software/tiny/
[2] https://github.com/bminor/bash/blame/master/general.c#L724

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


Golfed DEB package
------------------

See [here](deb/) for the writeup for this entry

Perl crasher
------------

See [here](perl/) for the writeup for this entry

