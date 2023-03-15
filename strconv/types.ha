// License: MPL-2.0
// (c) 2021 Andri Yngvason <andri@yngvason.is>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

// Indicates that the input string is not an integer. Contains the index of the
// first nondigit rune.
export type invalid = !size;

// Indicates that the input number is too large to be represented by the
// requested data type.
export type overflow = !void;

// Any error which may be returned from a strconv function.
export type error = !(invalid | overflow);

// The valid numeric bases for numeric conversions.
export type base = enum uint {
	// Base 2, binary
	BIN = 2,
	// Base 8, octal
	OCT = 8,
	// Base 10, decimal
	DEC = 10,
	// Base 16, UPPERCASE hexadecimal
	HEX_UPPER = 16,
	// Alias for HEX_UPPER
	HEX = 16,
	// Base 16, lowercase hexadecimal
	HEX_LOWER = 17,
};

// Converts an strconv [[error]] into a user-friendly string.
export fn strerror(err: error) str = {
	match (err) {
	case invalid =>
		return "Input string is not an integer";
	case overflow =>
		return "Input number overflows integer type";
	};
};
