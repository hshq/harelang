type jmpbuf = struct {
	__jb: arch_jmpbuf,
	__fl: size,
	__ss: [128z / size(size)]size,
};

fn setjmp(buf: *jmpbuf) int;

@noreturn fn longjmp(buf: *jmpbuf, n: int) void;
