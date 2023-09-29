// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Indicates that the input string doesn't have the requested number format
// (integer or float). Contains the index of the first invalid rune.
export type invalid = !size;

// Indicates that the input member can't be represented by the requested data
// type.
export type overflow = !void;

// Any error which may be returned from a strconv function.
export type error = !(invalid | overflow);

// The valid numeric bases for numeric conversions.
export type base = enum uint {
	// Default base - decimal
	DEFAULT = 0,

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
		return "Input string doesn't have the requested number format";
	case overflow =>
		return "Input number doesn't fit into requested type";
	};
};
