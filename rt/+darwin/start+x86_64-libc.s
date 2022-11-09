.text
.global _start
_start:
	xor %rbp, %rbp
	and $-16, %rsp
	leaq -8(%rsi), %rdi
	call _rt.start_darwin


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
