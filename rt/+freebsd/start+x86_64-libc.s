.text
.global _start
_start:
	xor %rbp, %rbp
	and $-16, %rsp
	call rt.start_freebsd
