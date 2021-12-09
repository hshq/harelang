@symbol("main") fn main() void;

export @noreturn fn start_ha() void = {
	// libc runs @init and @fini for us
	main();
	exit(0);
};
