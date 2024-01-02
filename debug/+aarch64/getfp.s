// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.section ".text.debug.getfp","ax"
.global debug.getfp
.type debug.getfp,@function
debug.getfp:
	mov x0, x29
	ret
