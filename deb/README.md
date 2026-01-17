# Golfed DEB package

Time is running out,so this writeup will have some parts in a rather bare state.

I got inspired by the 67 byte PIP package submission, and wanted to do something similar for Debian packages.

The folder contains all the scripts I was using, the main being `doit.sh`. `tar.asm` is a custom tar program which creates really barebones/nicely compressable tar files. `tarify` is an older script of mine, which changes a few bytes in arbritary files to give them a valid tar checksum. It was for duping `file` into thinking random files were tar files, but it worked nicely here to create actual tar files.o

## DEB files

.deb files are the package files used by Debian, and Ubuntu/Mint/other Debian forks by extension. They are basically AR archives with 3 files: debian-archive, control.tar and data.tar.

`debian-archive` must be the first file in the archive, and contains the version number of the package file. It also creates an easy-to-look for signature for the `file` tool.

`control.tar` contains all the metadata. It can be compressed, with older `dpkg` versions only supporting gzip, but newer versions support a lot more compressors.

`data.tar` contains the actual files that get installed onto the system. It can also be compressed like control.tar.

## Minifying it

One of the first things I implemented was creating better compressible tarfiles, by switching to the old v7 format. It has a lot less metadata, which helps compression. Setting owner/group and timestamp to zero also helps:
```
TZ=UTC tar -H v7 -b1 --owner=0 --group=0 --mtime="1970/1/1" -c -f "$out" "$@"
truncate -s -1024 "$out"
```
To my surprise, Zstandard files were pretty consistently smaller than gzip files, even for very small files. I.e. xz normally has good compression, but it's header is huge compared to plain gzip.

## Getting more serious with minification

The v7 tar files still have a lot of metadata in it, so I created a custom tar program with an unholy mix of shell script and assembler (see `tar.asm`). Ofc that file is a shell/asm polyglot too.

Tar is quite a flexible format, with no definitive standard for older file versions. So, while e.g. file attributes are *supposed* to be in octal (000), many untar programs also accept binary zeroes. GNU tarinterprets that as literal 000 permissions, but e.g. the tar from python interprets it as 'no/default file permissions'. This can lead to unreadable files, so the default file mode can be overridden with the `MODE` env variable in `tar.asm`.

## Old deb format?

Reading `man 5 deb` I stumbled over this sentence:
> The format described here is used since Debian 0.93; details of the old format are described in deb-old(5).

...old format? Yep, there was an old deb format, and it is still supported by current dpkg versions! Unfortunately it doesn't support anything else but gzip for the control.tar, but it makes that up by being very concise otherwise.

The header consists of two newline-delimited lines: the package version, and the file size of the control.tar file in ASCII decimal. Directly followed by the control.tar, and the *optional* data.tar. I'm not 100% sure if that is just a lucky coincidence of a null byte file actually being a kind-of valid tar and/or also being a valid gzip file, or if this was a deliberate design decision.

The package version needs to start with "0.93", and needs to be at least 8 bytes long including newline, so I chose
```
0.93666

```
for all old deb files.


## Bonus: 57 byte pip package
`H4sIAAAAAAACAyvQL04tKS3QK6hkoDswNMAubmQKlKELGAUFRZl5JRpmmiPT96MAAELqbJ0ABAAA`

10 bytes smaller than https://github.com/binarygolf/BGGP/issues/161 by using the custom tar program. Directory name is 'p', which leads to the tar checksum matching the file size:
```
00000070: 0000 0000 0000 0000 0000 0000 3130 0000  ............10..
00000080: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000090: 0000 0000 3235 3130 0000 0000 0000 0000  ....2510........
```
, saving 1 byte compared to other directory names


## Cramming in BGGP4

`dpkg` executes various scripts from the control tar if they exist, which all run with `/` as the working directory, so replicating the deb file to your current working directory should be impossible, right?
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
* `cd /*/$PPID` changes directory to the `/proc/<PPID>/` folder. The star works because there aren't many purely numerical directories in the second level under the root folder, and it saves some precious bytes.
* `set `\``tr '\0' ' '<cmdline`\` is doing quite a lot at once:
  * `tr '\0' ' '<cmdline`: this pipes `cmdline` into tr, replacing binary zeroes with whitespaces
  * `set -- $foo` is used for splitting a variable along the characters specified in `$IFS` (which defaults to space/newline/tab). But where did the `--` go? Turns out it's not needed if there's no way the input string could be mistaken for a shell option (setting shell options is the primary use of set, e.g. `set -ue`). It's a bit unclear if this was a planned or unplanned feature, but I gladly take the bytes saved.
* The `cd` and `cp` lines are pretty self-evident: Go to the parents working directory, and copy the parents third argument to "6". Please note that this works with both absolute and relative paths to the deb file
* The last line merely exits the script with an error message, due to it being a syntax error

This file is saved as `preinst`, meaning it gets executed before the package starts installing

## Hiding a bit of BGGP5 in the gzip header

We can hide some data in gzip headers. According to RFC1952:
```
      Each member has the following structure:

         +---+---+---+---+---+---+---+---+---+---+
         |ID1|ID2|CM |FLG|     MTIME     |XFL|OS | (more-->)
         +---+---+---+---+---+---+---+---+---+---+
```
The first 3 bytes are fixed, FLG we can change within reason, and the following 6 bytes can be an arbritary value. What we actually want to put in the header is
```
curl -L 6l.al
```
But this does not fit into the 6 available bytes. We can set FLG.FNAME, to specify that the original file name is after the header, delimited by a null byte:
```
printf '\37\213\10\10\n%s\n\0' "curl -L 6l.al" > "$OLDTAR"
dd if=control.tar.gz ibs=10 skip=1 conv=notrunc oflag=append of="$OLDTAR"
```
When we check with `file` we see the following:
```
c2.tgz: gzip compressed data, was "-L 6l.al", last modified: Thu Nov  7 15:28:10 2030, original size modulo 2^32 2048
```

The deb file can now also be run as a shell script:
```
# bash bggp456.deb
bggp456.deb: line 1: 0.93666: command not found
bggp456.deb: line 2: 170: command not found
bggp456.deb: line 3: $'\037\213\b\b': command not found
Another #BGGP6 download!!!!!! Hi @binarygolf https://binary.golf/6
bggp456.deb: line 5: $'3\021{\b': command not found
bggp456.deb: line 5: $'\352\226\036\355m\034\326X\006\337\305o\205EJza\037\a\2059X\373\357\377\266\202I$\344\
```

## Odds & ends
`smallest.deb` is 58 bytes, the smallest I could get a deb file to still somehow output '6':
```
# dpkg -i smallest.deb
dpkg: error processing archive smallest.deb (--install):
 parsing file '/var/lib/dpkg/tmp.ci/control' near line 0:
 end of file after field name '6'
Errors were encountered while processing:
 smallest.deb
```
It's basically and old deb file with the `control` file just containing the number 6. dpkg will error out with a parsing error.


`exec.deb` is the smallest deb that actually executes code when you try to install it:
```
b# dpkg -i smallest.deb
dpkg: error processing archive smallest.deb (--install):
 parsing file '/var/lib/dpkg/tmp.ci/control' near line 0:
 end of file after field name '6'
Errors were encountered while processing:
 smallest.deb
root@DESKTOP-NT8EGHQ:/home/balou/iv/bggp6/writeup/deb# dpkg -i exec.deb
dpkg: warning: parsing file '/var/lib/dpkg/tmp.ci/control' near line 4 package '6':
 missing 'Description' field
dpkg: warning: parsing file '/var/lib/dpkg/tmp.ci/control' near line 4 package '6':
 missing 'Maintainer' field
Selecting previously unselected package 6.
(Reading database ... 138190 files and directories currently installed.)
Preparing to unpack exec.deb ...
ls: cannot access '6': No such file or directory
dpkg: error processing archive exec.deb (--install):
 new 6 package pre-installation script subprocess returned error exit status 2
Errors were encountered while processing:
 exec.deb
```
The 'code' consists of just `ls 6` (which is smaller than `echo 6`).

It is also a shell polylgot:
```
# bash exec.deb
exec.deb: line 1: 0.93666: command not found
exec.deb: line 2: 113: command not found
exec.deb: line 3: $'\037\213\b': command not found
```

