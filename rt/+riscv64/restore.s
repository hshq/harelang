.section ".text.rt.restore","ax"
.global rt.restore
.type rt.restore, %function
rt.restore:
	li a7, 139 # SYS_rt_sigreturn
	ecall

