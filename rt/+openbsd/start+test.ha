// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The real main function.
@symbol(".main") fn main() void;

@symbol("__test_main") fn test_main() size;

// The setup of envp and args is done here. This is called by crt0 before
// normal init functions are called.
export @symbol("preinit_hare") fn preinit_hare(
	c_argc: int,
	c_argv: *[*]*u8,
	c_envp: *[*]nullable *u8
) void = {
	argc = c_argc: size;
	argv = c_argv;
	envp = c_envp;
};

// The purpose of this "fake" main function is to make sure we exit with the
// correct exit code in the case that rt::exit() is not called from within the
// program. The intilization and finilization functions are not run from here,
// they are ran by crt0.
export @symbol("main") fn _main() void = {
	const ret = if (test_main() > 0) 1 else 0;
	exit(ret);
};
