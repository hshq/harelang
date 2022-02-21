// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

type jmpbuf = struct {
	__jb: arch_jmpbuf,
	__fl: size,
	__ss: [128 / size(size)]size,
};

fn setjmp(buf: *jmpbuf) int;

@noreturn fn longjmp(buf: *jmpbuf, n: int) void;
