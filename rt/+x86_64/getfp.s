.section ".text.rt.getfp","ax"
.global rt.getfp
.type rt.getfp,@function
rt.getfp:
	endbr64
	mov (%rbp),%rax
	ret
