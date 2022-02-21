// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>

export fn start_linux() void = {
	// Here we use a cool strategy of re-constructing argv and argc without
	// knowing their original values. Since environ is placed just after
	// them, it's possible to traverse backwards calculating how many
	// entries were processed and comparing that value to the one at
	// current position.
	let argv_ptr = c_environ: uintptr - size(*char): uintptr * 2;
	let i = 0z;
	for (*(argv_ptr: **char): uintptr: size != i; i += 1) {
		argv_ptr -= size(*char): uintptr;
	};

	argc = i;
	argv = (argv_ptr + size(*char): uintptr): **char;
	envp = c_environ;
};

@init fn start_linux() void = start_linux();

let @symbol("environ") c_environ: *[*]nullable *char;
