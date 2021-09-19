.section .text.rt.syscall0
.global rt.syscall0
rt.syscall0:
	addi sp, sp, -32
	sd s0, 24(sp)
	addi s0, sp, 32
	sd a0, -24(s0)
	ld a7, -24(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 24(sp)
	addi sp, sp, 32
	jr ra

.section .text.rt.syscall1
.global rt.syscall1
rt.syscall1:
	addi sp, sp, -32
	sd s0, 24(sp)
	addi s0, sp, 32
	sd a0, -24(s0)
	sd a1, -32(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 24(sp)
	addi sp, sp, 32
	jr ra

.section .text.rt.syscall2
.global rt.syscall2
rt.syscall2:
	addi sp, sp, -48
	sd s0, 40(sp)
	addi s0, sp, 48
	sd a0, -24(s0)
	sd a1, -32(s0)
	sd a2, -40(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ld a1, -40(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 40(sp)
	addi sp, sp, 48
	jr ra

.section .text.rt.syscall3
.global rt.syscall3
rt.syscall3:
	addi sp, sp, -48
	sd s0, 40(sp)
	addi s0, sp, 48
	sd a0, -24(s0)
	sd a1, -32(s0)
	sd a2, -40(s0)
	sd a3, -48(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ld a1, -40(s0)
	ld a2, -48(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 40(sp)
	addi sp, sp, 48
	jr ra

.section .text.rt.syscall4
.global rt.syscall4
rt.syscall4:
	addi sp, sp, -64
	sd s0, 56(sp)
	addi s0, sp, 64
	sd a0, -24(s0)
	sd a1, -32(s0)
	sd a2, -40(s0)
	sd a3, -48(s0)
	sd a4, -56(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ld a1, -40(s0)
	ld a2, -48(s0)
	ld a3, -56(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 56(sp)
	addi sp, sp, 64
	jr ra

.section .text.rt.syscall5
.global rt.syscall5
rt.syscall5:
	addi sp, sp, -64
	sd s0, 56(sp)
	addi s0, sp, 64
	sd a0, -24(s0)
	sd a1, -32(s0)
	sd a2, -40(s0)
	sd a3, -48(s0)
	sd a4, -56(s0)
	sd a5, -64(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ld a1, -40(s0)
	ld a2, -48(s0)
	ld a3, -56(s0)
	ld a4, -64(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 56(sp)
	addi sp, sp, 64
	jr ra

.section .text.rt.syscall6
.global rt.syscall6
rt.syscall6:
	addi sp, sp, -80
	sd s0, 72(sp)
	addi s0, sp, 80
	sd a0, -24(s0)
	sd a1, -32(s0)
	sd a2, -40(s0)
	sd a3, -48(s0)
	sd a4, -56(s0)
	sd a5, -64(s0)
	sd a6, -72(s0)
	ld a7, -24(s0)
	ld a0, -32(s0)
	ld a1, -40(s0)
	ld a2, -48(s0)
	ld a3, -56(s0)
	ld a4, -64(s0)
	ld a5, -72(s0)
	ecall
	mv a5, a0
	mv a0, a5
	ld s0, 72(sp)
	addi sp, sp, 80
	jr ra
