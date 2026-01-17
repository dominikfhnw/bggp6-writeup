# Golfed DEB package

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


