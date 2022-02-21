// License: MPL-2.0
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export @noreturn fn start_linux(iv: *[*]uintptr) void = {
	// TODO: Find & parse auxv
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*char;
	envp = &argv[argc + 1]: *[*]nullable *char;
	start_ha();
};
