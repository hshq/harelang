// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Compares two strings by their Unicode codepoint sort order. Zero is returned
// if the strings are equal, a negative value if a is less than b, or a positive
// value if a is greater than b.
export fn compare(a: str, b: str) int = {
	let a = toutf8(a), b = toutf8(b);
	let ln = if (len(a) < len(b)) (len(a), -1) else (len(b), 1);
	for (let i = 0z; i < ln.0; i += 1) {
	        if (a[i] != b[i]) {
	                return a[i]: int - b[i]: int;
	        };
	};
	return if (len(a) == len(b)) 0 else ln.1;
};

@test fn compare() void = {
	assert(compare("ABC", "ABC") == 0);
	assert(compare("ABC", "AB") > 0);
	assert(compare("AB", "ABC") < 0);
	assert(compare("BCD", "ABC") > 0);
	assert(compare("ABC", "こんにちは") < 0);
	assert(compare("ABC", "abc") < 0);
};
