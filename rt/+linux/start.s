.text
.global _start
_start:
	xor %rbp, %rbp
	movq %rsp, %rdi
	call rt.start_ha
