// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

// Pads a string's start with 'prefix' until it reaches length 'target_len'.
// The caller must free the return value.
export fn padstart(s: str, prefix: rune, target_len: size) str = {
	if (len(s) >= target_len) {
		return dup(s);
	};
	let res: []u8 = alloc([], target_len);
	for (let i = 0z; i < target_len - len(s); i += 1) {
		append(res, utf8::encoderune(prefix)...);
	};
	append(res, toutf8(s)...);
	return fromutf8_unsafe(res[..target_len]);
};

@test fn padstart() void = {
	let s = padstart("2", '0', 5);
	assert(s == "00002");
	free(s);

	let s = padstart("12345", '0', 5);
	assert(s == "12345");
	free(s);

	let s = padstart("", '0', 5);
	assert(s == "00000");
	free(s);
};

// Pads a string's end with 'prefix' until it reaches length 'target_len'.
// The caller must free the return value.
export fn padend(s: str, prefix: rune, target_len: size) str = {
	if (len(s) >= target_len) {
		return dup(s);
	};
	let res: []u8 = alloc([], target_len);
	append(res, toutf8(s)...);
	for (let i = 0z; i < target_len - len(s); i += 1) {
		append(res, utf8::encoderune(prefix)...);
	};
	return fromutf8_unsafe(res[..target_len]);
};

@test fn padend() void = {
	let s = padend("2", '0', 5);
	assert(s == "20000");
	free(s);

	let s = padend("12345", '0', 5);
	assert(s == "12345");
	free(s);

	let s = padend("", '0', 5);
	assert(s == "00000");
	free(s);
};
