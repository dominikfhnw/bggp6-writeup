%if 0
#DUMP="--no-addresses -Mintel"

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

%define	EOFF 0xa36
%include "main.mac"
%define REG_ASSERT 0
%define stack_cleanup 0

elf	0x0d439000
rset	eax, 0x4
rset	ebx, 0x1

print	'6'
rset	eax, 1
exit

ELF_PHDR

%include "regdump2.mac"
