.text
.global _start
_start:
	mov 	x29, #0
	mov 	x30, #0

	; platformstart-libc.ha:
	sub		x0, x1, #8

	; platformstart+aarch64-libc.ha 1:
	; stp		x2, x3, [sp, #-16]!
	; stp		x0, x1, [sp, #-16]!
	; mov		x0, sp

	; platformstart+aarch64-libc.ha 2:

	b 		_rt.start_darwin

.include "start+libc.s"

