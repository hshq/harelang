// Concatenates two or more strings. The caller must free the return value.
export fn concat(strs: str...) str = {
	let z = 0z;
	for (let i = 0z; i < len(strs); i += 1z) {
		z += len(strs[i]);
	};
	let new = alloc([]u8, [], z + 1z);
	for (let i = 0z, j = 0z; i < len(strs); i += 1z) {
		append(new, ...to_utf8(strs[i]));
		j += len(strs[i]);
	};
	append(new, 0u8);
	return from_utf8(new[..z]);
};

@test fn concat() void = {
	let s = concat("hello ", "world");
	assert(s == "hello world");
	assert((s: *const char: *[*]u8)[len(s)] == 0u8);
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
