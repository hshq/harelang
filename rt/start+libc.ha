// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

@symbol(".main") fn main() void;
@symbol("exit") fn c_exit(status: int) void;

const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

export fn init() void = void;

// Run all global finalization functions.
export fn fini() void = {
	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1) {
		fini_start[i]();
	};
};

export @symbol("main") @noreturn fn start_ha() void = {
	// libc runs @init and @fini for us (unless rt::exit() is called)
	main();
	c_exit(0);
};
