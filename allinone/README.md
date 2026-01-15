Palindromic Polyglot Replicator Crasher Downloader
==================================================

This is my "main" entry for BGGP#6. The goal was to implement as many BGGP challenges as possible. I also managed to fix code in a 3rd-party application that pertains to my entry.
The main file format of this entry is an ELF executable for Linux on the x86 platform. The total file size is 223 bytes.

The writeup consists of two parts: this file gives an overview, and the source file itself ([link](es.asm)) contains lots of comments with more technical details. The source relies on my unreleased assembler library, but the sources should be clear even without it. I can release the sources if anyone is interested, it just is in a perpetually unfinished and messy state.

Executing it
------------

Copy the file over to any modern-ish x86/x64 Linux distribution, and make it executable with `chmod +x`. Choose a filename ending with ".com" if you want to run it as a DOS program.

If you execute it without any further steps, it will create a copy of itself in a file called "6", it will download and display from "https://binary.golf/6/6", and it will kill your shell.

The last action might impede with your ability to see the downloaded output, so to stop the program from killing your shell you might want to type `trap 'echo trapped QUIT' 3` beforehand.

Expected output:
```
$ trap 'echo trapped QUIT' 3
$ ./e.com
Another #BGGP6 download!!!!!! Hi @binarygolf https://binary.golf/6
trapped QUIT
$ ls -l 6 e.com
---------- 1 dominikr dominikr 223 Jan 15 15:27 6
-rwxr-xr-x 1 dominikr dominikr 223 Jan 15 15:24 e.com*
$ dosbox e.com
6 [in separate dosbox window]
```

Do a `rm 6` before you run the program a second time, as errors during creat() are not handled gracefully

Downloader/BGGP5
----------------
This was the first functionality I implemented: call curl with an execve() syscall. As this is the last part of the final program, no space is wasted for doing any exit() syscalls, as execve() itself will end the program.

```
201341      0.000306 [  11] [3d05b072] execve("/bin/curl", ["/bin/curl", "-L", "6l.al/bin/curl"], NULL <detached ...>
```

Several entries in the original BGGP5 contest used a custom domain, and my entry continues this tradition. The domain chosen is `6l.al`. The first "6" in the name was first chosen to make it easier to print "6" as required by BGGP6, until the contents of the link target were updated to already include the number. It now still serves a purpose in displaying the number in the curl error message if internet connectivity is not available. My thanks here go out to Albania for 1. allowing 2-letter domains 2. offering domain registration at a very modest price.

The code itself does not look very fancy at all: a null value, the offsets for the strings "6l.al", "-L" and "/bin/curl" are pushed onto the stack. One trick to save space was to only fully set `ebx` to the address of the string offset once, and only update `bl` subsequently.

The full URL accessed is also "6l.al/bin/curl", as this saved a zero-delimiter byte. Some previous version also set argv[0] to "6l.al" instead of "/bin/curl", but this did not save any space in the final version.

If time permits, I will try to submit a standalone version, as it's size of 71 byte is below any other original BGGP5 ELF entries.


Polyglot/BGGP2
--------------

First I wanted to make an ELF/shell polyglot again, but the recent changes in bash5 that specifically check for ELF headers made me rethink that.

I finally settled on DOS com file, as they have no predefined header and are thus ideal for golfing. From the view of DOS, the whole entry looks like this:
```
00000000  7F45              jg 0x47
...
00000047  B036              mov al,0x36
00000049  CD29              int 0x29
0000004B  C3                ret
...
```
The ELF header decodes to a jump to 0x47 in 16-bit assembly (the 'greater' condition is always true when the executable starts). To position the relevant code at offset 0x47 I used a nasm macro, see [the source](es.asm#L85) for further details.


Palindrome/BGGP1
----------------

The first attempts at a palindrome that executes beyond the halfway point used a dummy `cmp` instruction which would read as a final mov and int 0x80 after the halfway point:
```
A980CDE189	test	eax,0x89e1cd80
[halfway point]
89E1		mov	ecx, esp
CD80		int	0x80
[garbage]
```

But while further optimizing this shorter variant was found:
```
0000006D  80CD00            or ch,0x0
[halfway point]
00000070  CD80              int 0x80
```
The `or` with 0 is equal to a no-op, and allows turning the program into a palindrome at a cost of just `n+1` additional bytes (n being the original program size).

Crash/BGGP3
-----------
This entry crashes the parent shell by sending a SIGQUIT signal to it:
```
201341      0.001894 [  64] [3d05b03e] getppid() = 201319
201341      0.000336 [  37] [3d05b043] kill(201319, SIGQUIT) = 0
```

Replicator/BGGP4
----------------
Many variants were tried, but finally the variant where the entry opens itself (using argv[0]), creat(), and then sendfile() was smallest in the end:
```
201341      0.001348 [   5] [3d05b024] open("./e.com", O_RDONLY) = 3
201341      0.000488 [   8] [3d05b032] creat("6", 000) = 4
201341      0.000486 [ 187] [3d05b03a] sendfile(4, 3, NULL, 4294967295) = 223
```

Please note that the file gets created with permissions '000', i.e. it is not readable by default for non-root users (or more exactly, for processes without the CAP_DAC_OVERRIDE
capability).


Buildscript
-----------

A script was used to build and test the binary during development. All of the 5 BGGP requirements were automatically tested (with the exception of the DOS COM polyglot, as dosbox does not allow redirecting to STDOUT).

The palindrome was also generated and tested automatically with a perl command ([source](es.asm#L25)), and an expected score was calculated.

The script is not separate from the assembler source code; the source code itself is a shell/nasm palindrome. This was achieved by having a conditional macro at the top of the file:
```
%if 0
<shell commands>
exit 
%endif

<nasm sources>
```

Scoring/Bonus points
--------------------
The ELF file uses an `e_machine` value of 6, which stands for "Intel MCU" according to `readelf`. The Linux kernel, on the other hand, uses the macro name `EM_486` for `e_machine` == 6 [1], and allows it as an alternative to the more commonly used `e_machine` == 3 for x86 binaries [2].
Many tools do not recognize this alternative value, and will fail to either load such a binary at all, or will fail to correctly disassemble such binaries. Radare2 was one of these tools, so I submitted two pull requests (for r2 itself, and for the repo with the test binaries) to fix this:
* https://github.com/radareorg/radare2/pull/24730
* https://github.com/radareorg/radare2-testbins/pull/112

Both were merged before the end of BGGP6.

Expected final score is (4096-223)+(5*256)+1024+256=6433.



References
----------

[1] https://elixir.bootlin.com/linux/v6.18-rc2/source/include/uapi/linux/elf-em.h#L12

[2] https://elixir.bootlin.com/linux/v6.18-rc2/source/arch/x86/include/asm/elf.h#L85
