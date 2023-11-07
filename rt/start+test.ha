// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("__test_main") fn test_main() size;

const @symbol("__init_array_start") init_start: [*]*fn() void;
const @symbol("__init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

export fn start_ha() never = {
	init();
	const nfail = test_main();
	fini();
	exit(if (nfail > 0) 1 else 0);
};
