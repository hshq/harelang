// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

@symbol("main") fn main() void;
@symbol("exit") fn c_exit(status: int) void;

export @noreturn fn start_ha() void = {
	// libc runs @init and @fini for us
	main();
	c_exit(0);
};
