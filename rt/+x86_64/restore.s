// Copied from musl

.section ".text.rt.restore","ax"
.global rt.restore
.global rt.restore_si
.type rt.restore,@function
.type rt.restore_si,@function
rt.restore:
rt.restore_si:
	movl $15, %eax
	syscall

