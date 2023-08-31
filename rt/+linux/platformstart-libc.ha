// License: MPL-2.0
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export fn start_linux(iv: *[*]uintptr) never = {
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;
	start_ha();
};
