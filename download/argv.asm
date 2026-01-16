%if 0
# simple execve wrapper in 45 bytes
# - give it setuid and use it as a backdoor
# - assemble it with FULL=1 environment variable, and use it to run programs gdb usually refuses to load
DUMP="--no-addresses -Mintel"
. ./newbuild.sh
%endif

; copy original env if true, NULL env otherwise
%define ENV 	1

%include "main.mac"
elf 0x3d0bb000
%if ELF_CUSTOM
	rset	eax, 0x0b
%endif

%if ENV
	pop	esi	; argc
%else
	;pop	ecx	; argc
	pop	esi	; argc
%endif

pop	ecx	; argv[0]

mov	ecx, esp
%if ENV
	lea	edx, [esp+esi*4]	; envp
%endif
pop	ebx
execve	ebx, ecx, edx

%if !ENV
	;db 'BAD'
%endif

ELF_PHDR

%include "regdump2.mac"

