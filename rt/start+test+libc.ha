// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>

export fn init() void = void;

// Run all global finalization functions.
export fn fini() void = {
	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1) {
		fini_start[i]();
	};
};

export @symbol("main") fn main() int = {
	const nfail = tests_main();
	return if (nfail > 0) 1 else 0;
};
