.section ".text.crypto.aes.x86ni_keyexp","ax"
.global crypto.aes.x86ni_keyexp
.type crypto.aes.x86ni_keyexp,@function
crypto.aes.x86ni_keyexp:
	pushq %rbp
	mov %rsp, %rbp

	pushq %rbx
	pushq %rcx
	pushq %rdx

	movq 0x10(%rbp), %rbx # &key
	movq 0x18(%rbp), %rax # keylen

	movq 0x28(%rbp), %rcx # &enk_rk

	mov $0x18, %rdx
	cmp %rax, %rdx
	je enc_key_192
	jle enc_key_256

enc_key_128:
	movdqu (%rbx), %xmm1
	movdqu %xmm1, (%rcx)
	aeskeygenassist $0x1, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x10(%rcx)
	aeskeygenassist $0x2, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x20(%rcx)
	aeskeygenassist $0x4, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x30(%rcx)
	aeskeygenassist $0x8, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x40(%rcx)
	aeskeygenassist $0x10, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x50(%rcx)
	aeskeygenassist $0x20, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x60(%rcx)
	aeskeygenassist $0x40, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x70(%rcx)
	aeskeygenassist $0x80, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x80(%rcx)
	aeskeygenassist $0x1b, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0x90(%rcx)
	aeskeygenassist $0x36, %xmm1, %xmm2
	call key_expand_128
	movdqu %xmm1, 0xa0(%rcx)

	# return rklen
	mov $176, %rax

	jmp dec_key
key_expand_128:
	vpslldq $0x4, %xmm1, %xmm3
	pxor %xmm3, %xmm1
	vpslldq $0x4, %xmm1, %xmm3
	pxor %xmm3, %xmm1
	vpslldq $0x4, %xmm1, %xmm3
	pxor %xmm3, %xmm1

	pshufd $0xff, %xmm2, %xmm2
	pxor %xmm2, %xmm1
	ret

enc_key_192:
	movdqu (%rbx), %xmm1
	movdqu 0x10(%rbx), %xmm3

	movdqu %xmm1, (%rcx)
	movdqu %xmm3, %xmm5

	aeskeygenassist $0x1, %xmm3, %xmm2
	call key_expand_192
	shufpd $0, %xmm1, %xmm5
	movdqu %xmm5, 0x10(%rcx)
	movdqu %xmm1, %xmm6
	shufpd $1, %xmm3, %xmm6
	movdqu %xmm6, 0x20(%rcx)

	aeskeygenassist $0x2, %xmm3, %xmm2
	call key_expand_192
	movdqu %xmm1, 0x30(%rcx)
	movdqu %xmm3, %xmm5

	aeskeygenassist $0x4, %xmm3, %xmm2
	call key_expand_192
	shufpd $0, %xmm1, %xmm5
	movdqu %xmm5, 0x40(%rcx)
	movdqu %xmm1, %xmm6
	shufpd $1, %xmm3, %xmm6
	movdqu %xmm6, 0x50(%rcx)

	aeskeygenassist $0x8, %xmm3, %xmm2
	call key_expand_192
	movdqu %xmm1, 0x60(%rcx)
	movdqu %xmm3, %xmm5

	aeskeygenassist $0x10, %xmm3, %xmm2
	call key_expand_192
	shufpd $0, %xmm1, %xmm5
	movdqu %xmm5, 0x70(%rcx)
	movdqu %xmm1, %xmm6
	shufpd $1, %xmm3, %xmm6
	movdqu %xmm6, 0x80(%rcx)

	aeskeygenassist $0x20, %xmm3, %xmm2
	call key_expand_192
	movdqu %xmm1, 0x90(%rcx)
	movdqu %xmm3, %xmm5

	aeskeygenassist $0x40, %xmm3, %xmm2
	call key_expand_192
	shufpd $0, %xmm1, %xmm5
	movdqu %xmm5, 0xa0(%rcx)
	movdqu %xmm1, %xmm6
	shufpd $1, %xmm3, %xmm6
	movdqu %xmm6, 0xb0(%rcx)

	aeskeygenassist $0x80, %xmm3, %xmm2
	call key_expand_192
	movdqu %xmm1, 0xc0(%rcx)
	movdqu %xmm3, %xmm5

	# return rklen
	mov $208, %rax

	jmp dec_key

key_expand_192:
	vpslldq $0x4, %xmm1, %xmm4
	pxor %xmm4, %xmm1
	vpslldq $0x4, %xmm1, %xmm4
	pxor %xmm4, %xmm1
	vpslldq $0x4, %xmm1, %xmm4
	pxor %xmm4, %xmm1

	pshufd $0x55, %xmm2, %xmm2
	pxor %xmm2, %xmm1

	pshufd $0xff, %xmm1, %xmm2
	vpslldq $0x4, %xmm3, %xmm4

	pxor %xmm4, %xmm3
	pxor %xmm2, %xmm3

	ret

enc_key_256:
	movdqu (%rbx), %xmm1
	movdqu 0x10(%rbx), %xmm3

	movdqu %xmm1, (%rcx)
	movdqu %xmm3, 0x10(%rcx)

	aeskeygenassist $0x1, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0x20(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0x30(%rcx)
	aeskeygenassist $0x2, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0x40(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0x50(%rcx)
	aeskeygenassist $0x4, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0x60(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0x70(%rcx)
	aeskeygenassist $0x8, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0x80(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0x90(%rcx)
	aeskeygenassist $0x10, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0xa0(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0xb0(%rcx)
	aeskeygenassist $0x20, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0xc0(%rcx)
	aeskeygenassist $0x0, %xmm1, %xmm2
	call key_expand_256_b
	movdqu %xmm3, 0xd0(%rcx)
	aeskeygenassist $0x40, %xmm3, %xmm2
	call key_expand_256_a
	movdqu %xmm1, 0xe0(%rcx)

	# return rklen
	mov $240, %rax

	jmp dec_key

key_expand_256_a:
	movdqa %xmm1, %xmm4
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm1
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm1
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm1

	pshufd $0xff, %xmm2, %xmm2
	pxor   %xmm2, %xmm1

	ret

key_expand_256_b:
	movdqa %xmm3, %xmm4
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm3
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm3
	pslldq $4, %xmm4
	pxor   %xmm4, %xmm3

	pshufd $0xaa, %xmm2, %xmm2
	pxor   %xmm2, %xmm3

	ret

dec_key:
	movq 0x40(%rbp), %rdx # &dec_rk

	# store key in reverse order, therefore add offset to last rk item
	add %rax, %rdx
	sub $16, %rdx


dec_key_start:
	movdqu 0x0(%rcx), %xmm1
	movdqu %xmm1, 0x0(%rdx)

	movdqu 0x10(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x10(%rdx)
	movdqu 0x20(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x20(%rdx)
	movdqu 0x30(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x30(%rdx)
	movdqu 0x40(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x40(%rdx)
	movdqu 0x50(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x50(%rdx)
	movdqu 0x60(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x60(%rdx)
	movdqu 0x70(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x70(%rdx)
	movdqu 0x80(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x80(%rdx)
	movdqu 0x90(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0x90(%rdx)

	mov $208, %rbx
	cmp %rax, %rbx
	je dec_key_192
	jle dec_key_256

	movdqu 0xa0(%rcx), %xmm1
	movdqu %xmm1, -0xa0(%rdx)

	jmp key_exp_end

dec_key_192:
	movdqu 0xa0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xa0(%rdx)
	movdqu 0xb0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xb0(%rdx)


	movdqu 0xc0(%rcx), %xmm1
	movdqu %xmm1, -0xc0(%rdx)

	jmp key_exp_end
dec_key_256:
	movdqu 0xa0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xa0(%rdx)
	movdqu 0xb0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xb0(%rdx)
	movdqu 0xc0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xc0(%rdx)
	movdqu 0xd0(%rcx), %xmm1
	aesimc %xmm1, %xmm1
	movdqu %xmm1, -0xd0(%rdx)


	movdqu 0xe0(%rcx), %xmm1
	movdqu %xmm1, -0xe0(%rdx)

key_exp_end:
	pxor %xmm0, %xmm0
	pxor %xmm1, %xmm1
	pxor %xmm2, %xmm2
	pxor %xmm3, %xmm3
	pxor %xmm4, %xmm4
	pxor %xmm5, %xmm5
	pxor %xmm6, %xmm6

	popq %rdx
	popq %rcx
	popq %rbx

	leave
	ret

.section ".text.crypto.aes.x86ni_asencrypt","ax"
.global crypto.aes.x86ni_asencrypt
.type crypto.aes.x86ni_asencrypt,@function
crypto.aes.x86ni_asencrypt:
	pushq %rbp
	mov %rsp, %rbp
	pushq %rbx
	pushq %rcx
	pushq %rdx

	movq 0x10(%rbp), %rbx # &rk
	movq 0x18(%rbp), %rax # rklen

	movq 0x28(%rbp), %rcx # &dest
	movq 0x40(%rbp), %rdx # &src

	movdqu (%rdx), %xmm0
	movdqu (%rbx), %xmm1
	pxor %xmm1, %xmm0

	movdqu 0x10(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x20(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x30(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x40(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x50(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x60(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x70(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x80(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0x90(%rbx), %xmm1
	aesenc %xmm1, %xmm0

	mov $208, %rdx
	cmp %rax, %rdx
	jl encrypt_256
	je encrypt_192

	movdqu 0xa0(%rbx), %xmm1
	aesenclast %xmm1, %xmm0
	jmp encrypt_end

encrypt_192:
	movdqu 0xa0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xb0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xc0(%rbx), %xmm1
	aesenclast %xmm1, %xmm0
	jmp encrypt_end

encrypt_256:
	movdqu 0xa0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xb0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xc0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xd0(%rbx), %xmm1
	aesenc %xmm1, %xmm0
	movdqu 0xe0(%rbx), %xmm1
	aesenclast %xmm1, %xmm0
	jmp encrypt_end

encrypt_end:

	movdqu %xmm0, (%rcx)

	pxor %xmm0, %xmm0
	pxor %xmm1, %xmm1

	popq %rdx
	popq %rcx
	popq %rbx

	leave
	ret

.section ".text.crypto.aes.x86ni_asdescrypt","ax"
.global crypto.aes.x86ni_asdecrypt
.type crypto.aes.x86ni_asdecrypt,@function
crypto.aes.x86ni_asdecrypt:
	pushq %rbp
	mov %rsp, %rbp

	pushq %rbx
	pushq %rcx
	pushq %rdx

	movq 0x10(%rbp), %rbx # &rk
	movq 0x18(%rbp), %rax # rklen

	movq 0x28(%rbp), %rcx # &dest
	movq 0x40(%rbp), %rdx # &src

	movdqu (%rdx), %xmm0
	movdqu (%rbx), %xmm1
	pxor %xmm1, %xmm0

	movdqu 0x10(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x20(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x30(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x40(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x50(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x60(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x70(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x80(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0x90(%rbx), %xmm1
	aesdec %xmm1, %xmm0

	mov $208, %rdx
	cmp %rax, %rdx
	je decrypt_192
	jl decrypt_256

	movdqu 0xa0(%rbx), %xmm1
	aesdeclast %xmm1, %xmm0
	jmp decrypt_end

decrypt_192:
	movdqu 0xa0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xb0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xc0(%rbx), %xmm1
	aesdeclast %xmm1, %xmm0
	jmp decrypt_end

decrypt_256:
	movdqu 0xa0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xb0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xc0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xd0(%rbx), %xmm1
	aesdec %xmm1, %xmm0
	movdqu 0xe0(%rbx), %xmm1
	aesdeclast %xmm1, %xmm0
	jmp decrypt_end

decrypt_end:
	movdqu %xmm0, (%rcx)

	pxor %xmm0, %xmm0
	pxor %xmm1, %xmm1

	popq %rdx
	popq %rcx
	popq %rbx

	leave
	ret

