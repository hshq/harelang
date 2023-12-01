// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol(".main") fn main() void;
@symbol("exit") fn c_exit(status: int) never;

const @symbol("__libc_init_array_start") init_start: [*]*fn() void;
const @symbol("__libc_init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

export @symbol("main") fn start_ha(c_argc: int, c_argv: *[*]*u8) never = {
	argc = c_argc: size;
	argv = c_argv;
	envp = c_envp;
	// we deliberately prevent libc from running @init for us, in order to
	// be able to initialize argc/argv/envp beforehand. we can still get
	// away with just using libc for @fini though
	init();
	main();
	c_exit(0);
};

let @symbol("environ") c_envp: *[*]nullable *u8;
