.text
.global _start
_start:
	mov x29, #0
	mov x30, #0
	mov x0, sp
	add sp, x0, #-16
	b rt.start_linux
