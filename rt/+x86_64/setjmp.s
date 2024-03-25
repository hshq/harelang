/* Copyright 2011-2012 Nicholas J. Kain, licensed under standard MIT license */

.section ".text.rt.setjmp","ax"
.global rt.setjmp
.type rt.setjmp,@function
rt.setjmp:
	/* no endbr64 here to avoid exploitation - this function cannot be the
	 * result of an indirect branch.
	 */
	mov %rbx,(%rdi)         /* rdi is jmp_buf, move registers onto it */
	mov %rbp,8(%rdi)
	mov %r12,16(%rdi)
	mov %r13,24(%rdi)
	mov %r14,32(%rdi)
	mov %r15,40(%rdi)
	lea 8(%rsp),%rdx        /* this is our rsp WITHOUT current ret addr */
	mov %rdx,48(%rdi)
	mov (%rsp),%rdx         /* save return addr ptr for new rip */
	mov %rdx,56(%rdi)
	xor %eax,%eax           /* always return 0 */
	ret
