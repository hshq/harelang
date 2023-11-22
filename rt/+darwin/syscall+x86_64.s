.text
_error:
	neg %rax
	ret

# 0x2000000: #define S(n) ((2 << 24) | (~(0xff << 24) & (n)))

.text # .section .text.rt.syscall0
.global _rt.syscall0
_rt.syscall0:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall1
.global _rt.syscall1
_rt.syscall1:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %rsi, %rdi
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall2
.global _rt.syscall2
_rt.syscall2:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall3
.global _rt.syscall3
_rt.syscall3:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall4
.global _rt.syscall4
_rt.syscall4:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall5
.global _rt.syscall5
_rt.syscall5:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %r9, %r8
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc _error
	ret

.text # .section .text.rt.syscall6
.global _rt.syscall6
_rt.syscall6:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %r9, %r8
	movq %rdx, %rsi
	movq 8(%rsp), %r9
	movq %rcx, %rdx
	syscall
	jc _error
	ret


.text # .section .text.rt.sys_pipe
.global _rt.sys_pipe
_rt.sys_pipe:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	# movq %rsi, %rdi
	syscall
	jc _error
	movl %eax, (%rsi)
	movl %edx, 4(%rsi)
	movq $0, %rax
	ret

.text # .section .text.rt.sys_fork
.global _rt.sys_fork
_rt.sys_fork:
	# movq %rdi, %rax
	leaq 0x2000000(%rdi), %rax
	syscall
	jc _error
	xorq %rdi, %rdi
	cmpq $1, %rdx
	cmoveq %rdi, %rax
	ret

.text
.global	_rt.get_c_errno
_rt.get_c_errno:
	pushq	%rbp
	movq	%rsp, %rbp
	callq	___error
	movl	(%rax), %eax
	popq	%rbp
	retq

.text
.global	_rt.set_c_errno
_rt.set_c_errno:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%rbx
	; pushq	%rax
	movl	%edi, %ebx
	callq	___error
	movl	%ebx, (%rax)
	; addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	retq
