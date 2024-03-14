.text
.global _start
_start:
	xor %rbp, %rbp
	and $-16, %rsp
	leaq -8(%rsi), %rdi
	call _rt.start_darwin

.include "rt/+darwin/start-libc.s"