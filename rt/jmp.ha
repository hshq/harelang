// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type jmp_buf = struct {
	__jb: arch_jmp_buf,
	__fl: size,
	__ss: [128 / size(size)]size,
};

export fn setjmp(buf: *jmp_buf) int;

export fn longjmp(buf: *jmp_buf, n: int) never;
