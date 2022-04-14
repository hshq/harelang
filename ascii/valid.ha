// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
// (c) 2021 Drew Devault <sir@cmpwn.com>
use strings;

// Returns true if a rune is a valid ASCII character.
export fn valid(c: rune) bool = c: u32 <= 0o177;

// Returns true if all runes in a string are valid ASCII characters.
export fn validstr(s: str) bool = {
	const s = strings::toutf8(s);
	for (let i = 0z; i < len(s); i += 1) {
		if (s[i] >= 0200) {
			return false;
		};
	};
	return true;
};

@test fn valid() void = {
	assert(valid('a') && valid('\0') && valid('\x7F'));
	assert(!valid('\x80') && !valid('こ'));
	assert(validstr("abc\0"));
	assert(!validstr("こんにちは"));
	assert(!validstr("ABCこんにちは"));
};
