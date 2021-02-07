.text
.global rt.syscall0
rt.syscall0:
	sub	sp, sp, #16
	str	x0, [sp, 8]
	ldr	x8, [sp, 8]
	svc 0
	add	sp, sp, 16
	ret

.global rt.syscall1
rt.syscall1:
	sub	sp, sp, #16
	str	x0, [sp, 8]
	str	x1, [sp]
	ldr	x8, [sp, 8]
	ldr	x0, [sp]
	svc 0
	add	sp, sp, 16
	ret

.global rt.syscall2
rt.syscall2:
	sub	sp, sp, #32
	str	x0, [sp, 24]
	str	x1, [sp, 16]
	str	x2, [sp, 8]
	ldr	x8, [sp, 24]
	ldr	x0, [sp, 16]
	ldr	x1, [sp, 8]
	svc 0
	add	sp, sp, 32
	ret

.global rt.syscall3
rt.syscall3:
	sub	sp, sp, #32
	str	x0, [sp, 24]
	str	x1, [sp, 16]
	str	x2, [sp, 8]
	str	x3, [sp]
	ldr	x8, [sp, 24]
	ldr	x0, [sp, 16]
	ldr	x1, [sp, 8]
	ldr	x2, [sp]
	svc 0
	add	sp, sp, 32
	ret

.global rt.syscall4
rt.syscall4:
	sub	sp, sp, #48
	str	x0, [sp, 40]
	str	x1, [sp, 32]
	str	x2, [sp, 24]
	str	x3, [sp, 16]
	str	x4, [sp, 8]
	ldr	x8, [sp, 40]
	ldr	x0, [sp, 32]
	ldr	x1, [sp, 24]
	ldr	x2, [sp, 16]
	ldr	x3, [sp, 8]
	svc 0
	add	sp, sp, 48
	ret

.global rt.syscall5
rt.syscall5:
	sub	sp, sp, #48
	str	x0, [sp, 40]
	str	x1, [sp, 32]
	str	x2, [sp, 24]
	str	x3, [sp, 16]
	str	x4, [sp, 8]
	str	x5, [sp]
	ldr	x8, [sp, 40]
	ldr	x0, [sp, 32]
	ldr	x1, [sp, 24]
	ldr	x2, [sp, 16]
	ldr	x3, [sp, 8]
	ldr	x4, [sp]
	svc 0
	add	sp, sp, 48
	ret

.global rt.syscall6
rt.syscall6:
	sub	sp, sp, #64
	str	x0, [sp, 56]
	str	x1, [sp, 48]
	str	x2, [sp, 40]
	str	x3, [sp, 32]
	str	x4, [sp, 24]
	str	x5, [sp, 16]
	str	x6, [sp, 8]
	ldr	x8, [sp, 56]
	ldr	x0, [sp, 48]
	ldr	x1, [sp, 40]
	ldr	x2, [sp, 32]
	ldr	x3, [sp, 24]
	ldr	x4, [sp, 16]
	ldr	x5, [sp, 8]
	svc 0
	add	sp, sp, 64
	ret
