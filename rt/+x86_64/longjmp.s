/* Copyright 2011-2012 Nicholas J. Kain, licensed under standard MIT license */

.section ".text.rt.longjmp","ax"
.global rt.longjmp
.type rt.longjmp,@function
rt.longjmp:
	/* no endbr64 here to avoid exploitation - this function cannot be the
	 * result of an indirect branch.
	 */
	xor %eax,%eax
	cmp $1,%esi             /* CF = val ? 0 : 1 */
	adc %esi,%eax           /* eax = val + !val */
	mov (%rdi),%rbx         /* rdi is the jmp_buf, restore regs from it */
	mov 8(%rdi),%rbp
	mov 16(%rdi),%r12
	mov 24(%rdi),%r13
	mov 32(%rdi),%r14
	mov 40(%rdi),%r15
	mov 48(%rdi),%rsp
	/* IBT: we cannot directly jump to the saved adress since this might be
	 * in the middle of the function where we are not going to have an
	 * endbr64. instead, we push the address to the stack and return to it
	 * in order to avoid an indirect branch.
	 */
	push 56(%rdi)           /* goto saved address without altering rsp */
	ret
