.section ".text.rt.cpuid_getvendorstr","ax"
.global rt.cpuid_getvendorstr
.type rt.cpuid_getvendorstr,@function
rt.cpuid_getvendorstr:
	pushq %rdx
	pushq %rcx
	pushq %rbx

	cpuid
	movl %ebx, (%rdi)
	movl %edx, 4(%rdi)
	movl %ecx, 8(%rdi)

	popq %rbx
	popq %rcx
	popq %rdx
	ret

.section ".text.rt.cpuid_getfeatureflags","ax"
.global rt.cpuid_getfeatureflags
.type rt.cpuid_getfeatureflags,@function
rt.cpuid_getfeatureflags:

	pushq %rdx
	pushq %rcx
	pushq %rbx

	movl $1, %eax
	cpuid

	movq %rdi, -0x8(%rsp)
	movq -0x8(%rsp), %rax
	movl %edx, (%rax)

	movq -0x8(%rsp), %rax
	add $0x4, %rax
	movl %ecx, (%rax)

	popq %rbx
	popq %rcx
	popq %rdx
	ret

