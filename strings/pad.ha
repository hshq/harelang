// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

// Pads the start of a string 's' with rune 'p' until the string reaches length
// 'maxlen'. The caller must free the return value.
export fn lpad(s: str, p: rune, maxlen: size) str = {
	if (len(s) >= maxlen) {
		return dup(s);
	};
	let res: []u8 = alloc([], maxlen);
	for (let i = 0z; i < maxlen - len(s); i += 1) {
		append(res, utf8::encoderune(p)...);
	};
	append(res, toutf8(s)...);
	return fromutf8_unsafe(res[..maxlen]);
};

@test fn lpad() void = {
	let s = lpad("2", '0', 5);
	assert(s == "00002");
	free(s);

	let s = lpad("12345", '0', 5);
	assert(s == "12345");
	free(s);

	let s = lpad("", '0', 5);
	assert(s == "00000");
	free(s);
};

// Pads the end of a string 's' with rune 'p' until the string reaches length
// 'maxlen'. The caller must free the return value.
export fn rpad(s: str, p: rune, maxlen: size) str = {
	if (len(s) >= maxlen) {
		return dup(s);
	};
	let res: []u8 = alloc([], maxlen);
	append(res, toutf8(s)...);
	for (let i = 0z; i < maxlen - len(s); i += 1) {
		append(res, utf8::encoderune(p)...);
	};
	return fromutf8_unsafe(res[..maxlen]);
};

@test fn rpad() void = {
	let s = rpad("2", '0', 5);
	assert(s == "20000");
	free(s);

	let s = rpad("12345", '0', 5);
	assert(s == "12345");
	free(s);

	let s = rpad("", '0', 5);
	assert(s == "00000");
	free(s);
};
