export fn start_linux(iv: *[*]uintptr) void = {
	// TODO: Find & parse auxv
	argc = iv[0z]: size;
	argv = &iv[1z]: *[*]*char;
	envp = &iv[1z + argc * size(*char) + 1z]: *[*]nullable *char;
	start_ha();
};
