// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export fn start_freebsd(iv: *[*]uintptr) never = {
	// TODO: Find & parse auxv
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;
	start_ha();
};
