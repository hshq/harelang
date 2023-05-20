.section ".text.rt.getfp","ax"
.global rt.getfp
.type rt.getfp,@function
rt.getfp:
	mv a0, fp
	ret
