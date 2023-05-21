// Copied from musl

.section ".text.rt.restore","ax"
.global rt.restore
.global rt.restore_si
.type rt.restore,@function
.type rt.restore_si,@function
rt.restore:
rt.restore_si:
	mov x8,#139
	svc 0

