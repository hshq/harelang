.text
.global _start
_start:
	xor %rbp, %rbp
	call rt.start_freebsd
