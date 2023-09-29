.section ".text.rt.feclearexcept","ax"
.global rt.feclearexcept
.type rt.feclearexcept,@function
rt.feclearexcept:
	and a0, a0, 0x1f
	# fflags = fflags & ~a0
	frcsr t0
	not a0, a0
	and t0, t0, a0
	fscsr t0
	ret

.section ".text.rt.feraiseexcept","ax"
.global rt.feraiseexcept
.type rt.feraiseexcept,@function
rt.feraiseexcept:
	and a0, a0, 0x1f
	# fflags = fflags | a0
	frcsr t0
	or t0, t0, a0
	fscsr t0
	ret

.section ".text.rt.fesetround","ax"
.global rt.fesetround
.type rt.fesetround,@function
rt.fesetround:
	fsrm a0
	ret

.section ".text.rt.fegetround","ax"
.global rt.fegetround
.type rt.fegetround,@function
rt.fegetround:
	frrm a0
	ret

.section ".text.rt.fetestexcept","ax"
.global rt.fetestexcept
.type rt.fetestexcept,@function
rt.fetestexcept:
	and a0, a0, 0x1f
	frcsr t0
	and a0, a0, t0
	ret
