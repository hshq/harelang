export fn start_linux(iv: *[*]uintptr) void = {
	// TODO: Find & parse auxv
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*char;
	envp = &iv[1 + argc * size(*char) + 1]: *[*]nullable *char;
	start_ha();
};
