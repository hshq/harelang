// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
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
export fn dupall(s: []str) []str = {
	let newsl: []str = alloc([], len(s));
	for (let i = 0z; i < len(s); i += 1) {
		append(newsl, dup(s[i]));
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
	assert(s == "");
	free(s);

	s = dup("hello");
	assert(s == "hello");
	free(s);
};

@test fn dupall() void = {
	const payload: []str = [];

	let s = dupall(payload);
	assert(len(s) == len(payload));
	for (let i = 0z; i < len(s); i += 1) {
		assert(s[i] == payload[i]);
	};
	freeall(s);

	const payload: []str = ["a", "aaa"];

	let s = dupall(payload);
	assert(len(s) == len(payload));
	for (let i = 0z; i < len(s); i += 1) {
		assert(s[i] == payload[i]);
	};
	freeall(s);
};
