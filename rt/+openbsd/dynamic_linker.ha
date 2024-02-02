// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Functions and types for interacting with the dynamic linker.
export type dl_info = struct {
	fname: nullable *u8,
	fbase: nullable *opaque,
	sname: nullable *u8,
	saddr: nullable *opaque,
};

// dlopen
// dlclose
// dlsym
// dladdr

export @symbol("dladdr") fn dladdr(addr: *opaque, info: *dl_info) int;

// dlctl
// dlerror

export @symbol("dlerror") fn dlerror() nullable *const u8;
