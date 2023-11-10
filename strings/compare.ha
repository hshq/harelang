// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sort::cmp;

// Compares two strings by their Unicode codepoint sort order. Zero is returned
// if the strings are equal, a negative value if a is less than b, or a positive
// value if a is greater than b.
export fn compare(a: str, b: str) int = {
	return cmp::strs(&a, &b);
};

@test fn compare() void = {
	assert(compare("ABC", "ABC") == 0);
	assert(compare("ABC", "AB") > 0);
	assert(compare("AB", "ABC") < 0);
	assert(compare("BCD", "ABC") > 0);
	assert(compare("ABC", "こんにちは") < 0);
	assert(compare("ABC", "abc") < 0);
};
