@symbol("main") fn main() void;

const @symbol("__init_array_start") init_start: [*]*fn() void;
const @symbol("__init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

export fn start_ha(iv: *[*]uintptr) void = {
	// TODO: Find & parse auxv
	argc = iv[0z]: size;
	argv = &iv[1z]: *[*]*char;
	envp = &iv[1z + argc * size(*char) + 1z]: *[*]nullable *char;

	const ninit = (&init_end: uintptr - &init_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < ninit; i += 1z) {
		init_start[i]();
	};

	main();

	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1z) {
		fini_start[i]();
	};

	exit(0);
};
