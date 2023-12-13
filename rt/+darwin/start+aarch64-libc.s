.text
.global _start
_start:
	mov 	x29, #0
	mov 	x30, #0

	; platformstart-libc.ha:
	add		x0, x1, #-8

	; platformstart+aarch64-libc.ha 1:
	; stp		x2, x3, [sp, #-16]!
	; stp		x0, x1, [sp, #-16]!
	; mov		x0, sp

	; platformstart+aarch64-libc.ha 2:

	b 		_rt.start_darwin


.private_extern ___init_array_start
___init_array_start = section$start$__DATA$.init_array

.private_extern ___init_array_end
___init_array_end = section$end$__DATA$.init_array

.private_extern ___fini_array_start
___fini_array_start = section$start$__DATA$.fini_array

.private_extern ___fini_array_end
___fini_array_end = section$end$__DATA$.fini_array

.private_extern ___test_array_start
___test_array_start = section$start$__DATA$.test_array

.private_extern ___test_array_end
___test_array_end = section$end$__DATA$.test_array
