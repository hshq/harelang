// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;

// Returns true if a rune is a valid ASCII character.
export fn valid(c: rune) bool = c: u32 <= 0o177;

// Returns true if all runes in a string are valid ASCII characters.
export fn validstr(s: str) bool = {
	const bytes = strings::toutf8(s);
	for (let byte .. bytes) {
		if (byte >= 0o200) {
			return false;
		};
	};
	return true;
};

@test fn valid() void = {
	assert(valid('a') && valid('\0') && valid('\x7F'));
	assert(!valid('\u0080') && !valid('こ'));
	assert(validstr("abc\0"));
	assert(!validstr("š"));
	assert(!validstr("こんにちは"));
	assert(!validstr("ABCこんにちは"));
};
