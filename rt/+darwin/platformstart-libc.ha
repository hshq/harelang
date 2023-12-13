// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// platformstart-libc.ha:
export fn start_darwin(iv: *[*]uintptr) never = {
	// TODO: Find & parse auxv
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;
	start_ha();
};

// platformstart+aarch64-libc.ha 1:
// export fn start_darwin(iv: *[*]uintptr) never = {
// 	// TODO: Find & parse auxv
// 	argc = iv[0]: size;
// 	argv = iv[1]: *[*]*u8;
// 	envp = &argv[argc + 1]: *[*]nullable *u8;
// 	start_ha();
// };

// platformstart+aarch64-libc.ha 2:
// export fn start_darwin(c: size, v: *[*]*u8, e: *[*]nullable *u8) never = {
// 	// TODO: Find & parse auxv
// 	argc = c;
// 	argv = v;
// 	envp = e;
// 	start_ha();
// };