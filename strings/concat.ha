// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Concatenates multiple strings. The caller must free the return value.
export fn concat(strs: str...) str = {
	let z = 0z;
	for (let s .. strs) {
		z += len(s);
	};

	let new: []u8 = alloc([], z);
	for (let s .. strs) {
		static append(new, toutf8(s)...);
	};
	return fromutf8_unsafe(new);
};

@test fn concat() void = {
	let s = concat("hello ", "world");
	defer free(s);
	assert(s == "hello world");

	let s = concat("hello", " ", "world");
	defer free(s);
	assert(s == "hello world");

	let s = concat("hello", "", "world");
	defer free(s);
	assert(s == "helloworld");

	let s = concat("", "");
	defer free(s);
	assert(s == "");

	let s = concat();
	defer free(s);
	assert(s == "");

	let s = concat("hello");
	defer free(s);
	assert(s == "hello");
};

// Joins several strings together by placing a delimiter between them. The
// caller must free the return value.
export fn join(delim: str, strs: str...) str = {
	let z = 0z;
	for (let i = 0z; i < len(strs); i += 1) {
		z += len(strs[i]);
		if (i + 1 < len(strs)) {
			z += len(delim);
		};
	};
	let new: []u8 = alloc([], z);
	for (let i = 0z; i < len(strs); i += 1) {
		static append(new, toutf8(strs[i])...);
		if (i + 1 < len(strs)) {
			static append(new, toutf8(delim)...);
		};
	};
	return fromutf8_unsafe(new);
};

@test fn join() void = {
	let s = join(".", "a", "b", "c");
	defer free(s);
	assert(s == "a.b.c");

	let s = join("", "a", "b", "c");
	defer free(s);
	assert(s == "abc");

	let s = join(".");
	defer free(s);
	assert(s == "");

	let s = join(".", "a");
	defer free(s);
	assert(s == "a");
};
