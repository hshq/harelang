const @symbol("__init_array_start") init_start: [*]*fn() void;
const @symbol("__init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

type test = struct {
	name: str,
	func: *fn() void,
};

const @symbol("__test_array_start") test_start: [*]test;
const @symbol("__test_array_end") test_end: [*]test;

fn print(msg: str) void = write(1, msg: *const char, len(msg));

export fn start_ha() void = {
	const ninit = (&init_end: uintptr - &init_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < ninit; i += 1z) {
		init_start[i]();
	};

	const ntest = (&test_end: uintptr - &test_start: uintptr): size / size(test);
	for (let i = 0z; i < ntest; i += 1z) {
		print(test_start[i].name);
		print("...");
		test_start[i].func();
		print("OK\n");
	};

	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1z) {
		fini_start[i]();
	};

	exit(0);
};

