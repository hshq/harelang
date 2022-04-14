// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
// (c) 2021 Drew Devault <sir@cmpwn.com>

// Returns true if a rune is a valid ASCII character.
export fn valid(c: rune) bool = c: u32 <= 0o177;

@test fn valid() void = {
	assert(valid('a') && valid('\0') && valid('\x7F'));
	assert(!valid('\x80') && !valid('こ'));
};
