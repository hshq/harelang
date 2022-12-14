// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Concatenates two or more strings. The caller must free the return value.
export fn concat(strs: str...) str = {
	let z = 0z;
	for (let i = 0z; i < len(strs); i += 1) {
		z += len(strs[i]);
	};
	let new: []u8 = alloc([], z);
	for (let i = 0z; i < len(strs); i += 1) {
		append(new, toutf8(strs[i])...);
	};
	return fromutf8_unsafe(new[..z]);
};

@test fn concat() void = {
	let s = concat("hello ", "world");
	assert(s == "hello world");
	free(s);

	s = concat("hello", " ", "world");
	assert(s == "hello world");
	free(s);

	s = concat("hello", "", "world");
	assert(s == "helloworld");
	free(s);

	s = concat("", "");
	assert(s == "");
	free(s);

	s = concat();
	assert(s == "");
	free(s);
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
		append(new, toutf8(strs[i])...);
		if (i + 1 < len(strs)) {
			append(new, toutf8(delim)...);
		};
	};
	return fromutf8_unsafe(new[..z]);
};

@test fn join() void = {
	let s = join(".", "a", "b", "c");
	assert(s == "a.b.c");
	free(s);

	let s = join("", "a", "b", "c");
	assert(s == "abc");
	free(s);

	let s = join(".");
	assert(s == "");
	free(s);

};
