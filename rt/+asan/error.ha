export @noreturn fn san_error_load8(addr: uintptr) void = {
	abort("Address sanitizer error detected");
};
