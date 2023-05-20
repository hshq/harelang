.section ".text.rt.getfp","ax"
.global rt.getfp
.type rt.getfp,@function
rt.getfp:
	mov (%rbp),%rax
	ret
