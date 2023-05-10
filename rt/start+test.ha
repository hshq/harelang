// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

@symbol("__test_main") fn test_main() size;

const @symbol("__init_array_start") init_start: [*]*fn() void;
const @symbol("__init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

// Run all global initialization functions.
export fn init() void = {
	const ninit = (&init_end: uintptr - &init_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < ninit; i += 1) {
		init_start[i]();
	};
};

// Run all global finalization functions.
export fn fini() void = {
	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1) {
		fini_start[i]();
	};
};

export @noreturn fn start_ha() void = {
	init();
	const nfail = test_main();
	fini();
	exit(if (nfail > 0) 1 else 0);
};
