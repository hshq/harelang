// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.section ".text.debug.getfp","ax"
.global debug.getfp
.type debug.getfp,@function
debug.getfp:
	endbr64
	movq %rbp,%rax
	ret
