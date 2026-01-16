# BGGP5/6 Downloader

The 71b version is basically the same as in my all-in-one solution with everything else removed (see [the writeup](../allinone) for details). It clocks in at 71 bytes, compared to the 81 bytes of the ELF32 w/o CLI winner from the original BGGP5 contest.

The header is based on Brian Raiters work. The main code disassembled:
```
3d0bb019:       b0 0b                   mov    al,0xb
3d0bb01b:       3d 04 00 00 00          cmp    eax,0x4
3d0bb020:       53                      push   ebx
3d0bb021:       bb 36 b0 0b 3d          mov    ebx,0x3d0bb036
3d0bb026:       53                      push   ebx
3d0bb027:       b3 45                   mov    bl,0x45
3d0bb029:       a9 20 00 01 00          test   eax,0x10020
3d0bb02e:       53                      push   ebx
3d0bb02f:       b3 3b                   mov    bl,0x3b
3d0bb031:       53                      push   ebx
3d0bb032:       89 e1                   mov    ecx,esp
3d0bb034:       cd 80                   int    0x80
```
One trick used is to start the program at offset 0x19, where it collides with the VirtAddr field - that's why the first 3 bytes of the code are equivalent to the first 3 bytes of the start address (0x3d0bb0). Source code is available in the same folder.


## Version with CLI arguments

45 bytes... smallest possible ELF32 program size. Beats the 76 byte version from last year. Funnily enough, I wrote this program even before knowing about BGGP...

```
3d0bb019:       b0 0b                   mov    al,0xb
3d0bb01b:       3d 04 00 00 00          cmp    eax,0x4
3d0bb020:       5e                      pop    esi
3d0bb021:       59                      pop    ecx
3d0bb022:       89 e1                   mov    ecx,esp
3d0bb024:       8d 14 b4                lea    edx,[esp+esi*4]
3d0bb027:       5b                      pop    ebx
3d0bb028:       cd 80                   int    0x80
```

To run: make it executable, and then simply type
`./argv /bin/curl -L https://binary.golf/6/6`
Or for nostalgia reasons:
`./argv /bin/curl -L https://binary.golf/5/5`

Do you think that's cheating? I think so too, but running with CLI arguments was explicitly allowed for BGGP5.

