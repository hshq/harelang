.text
.global _start
_start:
	mv a0, sp
	andi sp, sp, -16
	tail rt.start_linux
