// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use types;

// Converts a byte slice into a string, but does not test if it is valid UTF-8.
// This is faster than the safe equivalent, but if the string is not valid UTF-8
// it may cause undefined behavior. The return value is borrowed from the input.
export fn fromutf8_unsafe(in: []u8) str = {
	const s = types::string {
		data     = in: *[*]u8,
		length   = len(in),
		capacity = len(in),
	};
	return *(&s: *const str);
};

// Converts a byte slice into a string. The return value is borrowed from the
// input. If the slice contains invalid UTF-8 sequences,
// [[encoding::utf8::invalid]] is returned instead.
export fn fromutf8(in: []u8) (str | utf8::invalid) = {
	utf8::validate(in)?;
	return fromutf8_unsafe(in);
};

// Converts a string to a UTF-8 byte slice. The return value is borrowed from
// the input.
export fn toutf8(in: str) []u8 = *(&in: *[]u8);

@test fn utf8() void = {
	assert(fromutf8([
		0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64,
	])! == "hello world");
	assert(fromutf8([])! == "");
};
