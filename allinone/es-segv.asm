%if 0
# alternative version which sends a SIGSEGV instead of a SIGQUIT to the parent. +4 bytes.
#DUMP="--no-addresses -Mintel"
rm -f ./6 ./out ./err ./trace

POSTBUILD='perl -0777pe '"'"'chop;$_=reverse'"'"' "$OUT" >> "$OUT"'
OUT="e.com"
NOEXIT=1
. ./newbuild.sh


# run&tests

fail(){
	echo -e "\e[31mBGGP$1 FAIL\e[m"
	exit 1
}
#set -x
SIG=
trap 'SIG=1;echo trapped ABRT'	6
trap 'SIG=1;echo trapped HUP'	1
trap 'SIG=1;echo trapped QUIT'	3
trap 'SIG=1;echo trapped SEGV'	11
strace -o trace -b execve -Dfrni ./"$OUT" > out 2> err
cat trace out

perl -0777pe '$_=reverse' "$OUT" > rev
cmp -l "$OUT" rev	|| fail 1
# dosbox e.com		# not automatic
[ "$SIG" = 1 ]		|| fail 3
test -f 6		|| fail 4
chmod u+r 6
cmp -l "$OUT" 6		|| fail 4
grep -q "BGGP6" out	|| fail 5

echo -e "\e[32mPASS\e[m"
SIZE=$(wc -c < $OUT)
SCORE=$(( (4096-$SIZE) + 5*256 ))
SCORE2=$(( SCORE + 1024 + 256 ))
echo "SCORE: $SCORE / $SCORE2"
exit 0

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
%define REG_ASSERT	0
%define MACHINE		6
%define stack_cleanup	0

%define BGGP2	1
%define BGGP3	1
%define DOS6	1
%define SELF	0

%define FILL nop
%macro setpos 1-2 FILL
	times $$-$+%1 %2
%endmacro

; macro to put down the DOS COM + rodata block anywhere
%macro doscom 0
	%if BGGP2
		reg_push
		setpos	0x45
		jmp	short %%nodos
		%if DOS6
			mov	al, '6'
			int	0x29
		%endif
		ret
		; we can't have rodata at the end because of the palindrome.
		; code will now be in the "rodata" section, but who cares.
		; only thing... nasm will do long jmps by default now,
		; so we explicitly have to jmp short
		[section .rodata align=1]
		url:	db '6l.al'
		curl:	db '/bin/curl',0
		ell:	db '-L',0
		;times 4 hlt

		%%nodos:
		reg_pop
	%endif
%endmacro

_begin:
elf	0x3d05b000	; the base address is also code
%if ELF_CUSTOM
	; the macros implement tracking of register values.
	; "set eax, 2" is functionally the same as "mov eax, 2",
	; but if e.g. eax is currently 1, the set macro will just emit "inc eax"
	; rset is for telling the macros that a value has changed outside of
	; its tracking. All values are internally tracked as unsigned numbers.
	; Negative numbers are for not precisely defined values.
	; -1 is any value, -2 is value =< 0xff, -3 for =< 0xffff,
	; and -4 for MSB unset (e.g. a positive signed number).
	rset	eax, 0x05
%endif

_bggp4:
pop	ebx		; argc
open	pop, O_RDONLY	; open ARGV[0]
rset	sc_ret, 3	; assume FD==3
			; 'sc_ret' stands for syscall return value.
			; i.e. eax on x86. x64 support is partially here,
			; riscv support is planned

string	ebx, '6'	; still space before PHDRs
			; puts a pointer to the string "6" in ebx.
			; as it is a short string, the macro will use
			; push 0x36; mov ebx,esp
set	esi, -1		; later needed for sendfile, here we have some space
ELF_PHDR 1		; macro to insert needed PHDR fields.
			; sets the correct offset, but we have to make sure
			; not to use it too early, or we'll waste space
creat	x, x		; 'x' stands for "don't care/keep register as is"
rset	sc_ret, 4

sendfile 4, 3, 0, -1	; maybe I should talk about what the code actually does.
			; For BGGP4: 
			;  * open() ARGV[0], i.e. ourselves
			;  * creat() a file called "6"
			;  * copy over ourselves to the new file with sendfile()
rset	sc_ret, -2

%if BGGP3
_bggp3:
%if !SELF
%define SIGNAL 11	; 3 because arg2 already contains 3 from sendfile() abve
ebx := getppid		; so this is one of the crazier/more experimental features
			; of my macros: assignable return values. Still a bit buggy though.
rset	ebx, -4
kill	x, SIGNAL
%else
kill	0, 0
%endif
rset	sc_ret, 0
%endif
;set	eax, SYS_execve	; 2 bytes of free space, pre-set eax value for BGGP5
doscom			; insert COM file/rodata
			; BGGP3 description:
			;  * Get parent PID: getppid()
			;  * kill() parent.
			; This satisfies BGGP3: our program is an input to a shell, which gets
			; killed if that input is ran.

_bggp5:
push0			; Create argv[] on the stack
mov	ebx, url
taint	ebx		; taint is identical to rset x, -1
push	ebx
mov	bl, ell		; Only update the lower 8 bits of our pointer. This saves a lot of bytes
push	ebx
mov	bl, curl
push	ebx

;execve	x, esp, 0	; this was in the older, non-palindromic version
set	eax, SYS_execve
set	edx, 0
mov	ecx, esp

or	ch, 0		; now this is the interesting part
; assembles as follows:
; 3d05b06d:       80 cd 00                or     ch,0x0
; Just a harmless NOP... but if we make an odd-sized palindrome, the next
; instruction then reads:
; 3d05b070:       cd 80                   int    0x80
; Et voilà... we have code execution beyond the halfway point with a 
; minimum of bytes spent

; The older, bigger, variant was
;db	0xa9, 0x80, 0xcd, 0xe1, 0x89
; It assembles to "cmp eax, SOMEVALUE", but backwards it executes
; "mov ecx,esp; int 0x80"




%include "regdump2.mac"
