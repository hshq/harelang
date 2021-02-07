use rt;
use types;

// Concatenates two or more strings. The caller must free the return value.
export fn concat(strs: str...) str = {
	let z = 0z;
	for (let i = 0z; i < len(strs); i += 1z) {
		z += len(strs[i]);
	};
	let new = alloc([]u8, [], z + 1z);
	let buf = new: *[*]u8;
	for (let i = 0z, j = 0z; i < len(strs); i += 1z) {
		rt::memcpy(&buf[j], strs[i]: *const char: *[*]u8, len(strs[i]));
		j += len(strs[i]);
	};
	buf[z + 1z] = 0u8;
	(&new: *types::string).length = z;
	return *(&new: *str);
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
