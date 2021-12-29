.section .text.rt.syscall0
.global rt.syscall0
rt.syscall0:
	mv a7, a0
	ecall
	ret

.section .text.rt.syscall1
.global rt.syscall1
rt.syscall1:
	mv a7, a0
	mv a0, a1
	ecall
	ret

.section .text.rt.syscall2
.global rt.syscall2
rt.syscall2:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	ecall
	ret

.section .text.rt.syscall3
.global rt.syscall3
rt.syscall3:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	ecall
	ret

.section .text.rt.syscall4
.global rt.syscall4
rt.syscall4:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	ecall
	ret

.section .text.rt.syscall5
.global rt.syscall5
rt.syscall5:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	mv a4, a5
	ecall
	ret

.section .text.rt.syscall6
.global rt.syscall6
rt.syscall6:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	mv a4, a5
	mv a5, a6
	ecall
	ret
