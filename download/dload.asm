%if 0
#DUMP="--no-addresses -Mintel"
POSTBUILD='truncate -s -1 "$OUT"'


. ./newbuild.sh

%endif

; BGGP1:
; * The binary you will craft will be the same executable when flipped backwards.
; * Minimum should execute 50% of it's bytes
; * Must execute within the mirrored section
; * Must read the same forwards as it does backwards
;
; BGGP2:
; * The host file must be a binary executable.
; * Overlap with at least one additional file of any type to create a polyglot
; * The host binary must return or print the number 2 when executed.
;
; BGGP3:
; * crash program
; * print "3" from crashed program
; * EIP = 0x33333333
;
; BGGP4:
; * Must return or print 4
; * Must create a file called 4
; * Must not execute the file it created
;
; BGGP5:
; * Be 4096 bytes or less
; * Download the text file at https://binary.golf/5/5
; * Display the file's contents in some way

%include "main.mac"
%define REG_ASSERT 0
%define stack_cleanup 0
;%assign ELF_OFFSET ELF_OFFSET - 1

%define FILL nop
%macro setpos 1-2 FILL
	times $$-$+%1 %2
%endmacro

_begin:
elf	0x3d0bb000
%if ELF_CUSTOM
	rset	eax, 0xb
%endif
push0
mov	ebx, url

push	ebx
mov	bl, ell
ELF_PHDR 1
.build:
push	ebx
mov	bl, curl
push	ebx
.execve:
;lea	sc_arg1, [sc_arg2 + (curl-url)]
;mov	bl, curl
execve	x, esp, 0

[section .rodata align=1]
url:	db '6l.al'
curl:	db '/bin/curl',0
ell:	db '-L',0

end:

filesize      equ     $ - $$

%include "regdump2.mac"
