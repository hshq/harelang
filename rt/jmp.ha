// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type jmpbuf = struct {
	__jb: arch_jmpbuf,
	__fl: size,
	__ss: [128 / size(size)]size,
};

export fn setjmp(buf: *jmpbuf) int;

export fn longjmp(buf: *jmpbuf, n: int) never;
