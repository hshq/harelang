.text
.global _start
_start:
	andi sp, sp, -16
	tail rt.start_freebsd
