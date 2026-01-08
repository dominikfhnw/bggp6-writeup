%if 0
. ./newbuild.sh
%endif

%define	EOFF 0xa36
%include "main.mac"

elf	0x6804b000
rset	eax, 0x4
mov	ecx, _off
pop	edx
write	0, ecx, x
jmp	$
ELF_PHDR

