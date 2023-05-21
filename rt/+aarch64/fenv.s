# This file is vendored from musl and is licensed under MIT license:
#
# ----------------------------------------------------------------------
# Copyright © 2005-2020 Rich Felker, et al.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ----------------------------------------------------------------------

.section ".text.rt.fegetround","ax"
.global rt.fegetround
.type rt.fegetround,%function
rt.fegetround:
	mrs x0, fpcr
	and w0, w0, #0xc00000
	ret

.section ".text.rt.fesetround","ax"
.global rt.fesetround
.type rt.fesetround,%function
rt.fesetround:
	mrs x1, fpcr
	bic w1, w1, #0xc00000
	orr w1, w1, w0
	msr fpcr, x1
	mov w0, #0
	ret

.section ".text.rt.fetestexcept","ax"
.global rt.fetestexcept
.type rt.fetestexcept,%function
rt.fetestexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	and w0, w0, w1
	ret

.section ".text.rt.feclearexcept","ax"
.global rt.feclearexcept
.type rt.feclearexcept,%function
rt.feclearexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	bic w1, w1, w0
	msr fpsr, x1
	mov w0, #0
	ret

.section ".text.rt.feraiseexcept","ax"
.global rt.feraiseexcept
.type rt.feraiseexcept,%function
rt.feraiseexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	orr w1, w1, w0
	msr fpsr, x1
	mov w0, #0
	ret

.section ".text.rt.fegetenv","ax"
.global rt.fegetenv
.type rt.fegetenv,%function
rt.fegetenv:
	mrs x1, fpcr
	mrs x2, fpsr
	stp w1, w2, [x0]
	mov w0, #0
	ret

// TODO preserve some bits
.section ".text.rt.fesetenv","ax"
.global rt.fesetenv
.type rt.fesetenv,%function
rt.fesetenv:
	mov x1, #0
	mov x2, #0
	cmn x0, #1
	b.eq 1f
	ldp w1, w2, [x0]
1:	msr fpcr, x1
	msr fpsr, x2
	mov w0, #0
	ret
