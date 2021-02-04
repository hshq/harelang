type test = struct {
	name: str,
	func: *fn() void,
};

const @symbol("__init_array_start") init_start: [*]*fn() void;
const @symbol("__init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;
const @symbol("__test_array_start") test_start: [*]test;
const @symbol("__test_array_end") test_end: [*]test;

let jmp: jmpbuf = jmpbuf { ... };
let reason: str = "";

export fn start_ha() void = {
	const ninit = (&init_end: uintptr - &init_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < ninit; i += 1z) {
		init_start[i]();
	};

	const ntest = (&test_end: uintptr - &test_start: uintptr): size / size(test);
	let maxname = 0z;
	for (let i = 0z; i < ntest; i += 1z) {
		if (len(test_start[i].name) > maxname) {
			maxname = len(test_start[i].name);
		};
	};

	let npass = 0z, nfail = 0z;
	print("Running ");
	print(ztos(ntest));
	print(" tests:\n\n");
	for (let i = 0z; i < ntest; i += 1z) {
		print(test_start[i].name);
		dots(maxname - len(test_start[i].name) + 3z);
		print(" ");

		if (setjmp(&jmp) != 0) {
			nfail += 1z;
			print("FAIL: ");
			print(reason);
			print("\n");
			continue;
		};
		test_start[i].func();

		npass += 1z;
		print("OK\n");
	};
	print("\n");
	print(ztos(npass));
	print(" passed; ");
	print(ztos(nfail));
	print(" failed; ");
	print(ztos(ntest));
	print(" tests completed.\n");

	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < nfini; i += 1z) {
		fini_start[i]();
	};

	exit(if (nfail > 0z) 1 else 0);
};

fn print(msg: str) void = write(1, msg: *const char, len(msg));

fn dots(n: size) void = {
	// XXX: this is slow, I guess
	for (let i = 0z; i < n; i += 1z) {
		print(".");
	};
};
