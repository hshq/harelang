.text
.global _start
_start:
	mov x29, #0
	mov x30, #0
	and sp, sp, #-16
	b rt.start_freebsd
