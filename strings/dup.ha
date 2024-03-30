// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Duplicates a string. Aborts on allocation failure.
export fn dup(s: const str) str = {
	const in = &s: *types::string;
	const id = match (in.data) {
	case null =>
		return ""; // Empty string
	case let b: *[*]u8 =>
		yield b;
	};
	let buf: []u8 = alloc(id[..in.length], in.length);
	let out = types::string {
		data = buf: *[*]u8,
		length = in.length,
		capacity = in.length,
	};
	return *(&out: *str);
};

// Creates a copy of a []str slice with all the strings duplicated. The result
// must be freed using [[freeall]].
export fn dupall(strs: []str) []str = {
	let newsl: []str = alloc([], len(strs));
	for (let s .. strs) {
		static append(newsl, dup(s));
	};
	return newsl;
};

// Frees all the strings in a slice and the slice itself. Inverse of [[dupall]].
export fn freeall(s: []str) void = {
	for (let i = 0z; i < len(s); i += 1) {
		free(s[i]);
	};
	free(s);
};

@test fn dup() void = {
	let s = dup("");
	defer free(s);
	assert(s == "");

	let s = dup("hello");
	defer free(s);
	assert(s == "hello");
};

@test fn dupall() void = {
	const payload: []str = [];

	let s = dupall(payload);
	defer freeall(s);
	assert(len(s) == len(payload));
	for (let i = 0z; i < len(s); i += 1) {
		assert(s[i] == payload[i]);
	};

	const payload: []str = ["a", "aaa"];

	let s = dupall(payload);
	defer freeall(s);
	assert(len(s) == len(payload));
	for (let i = 0z; i < len(s); i += 1) {
		assert(s[i] == payload[i]);
	};
};
