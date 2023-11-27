// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Returns a slice (borrowed from given input slice) after trimming off of
// the start of the input slice the bytes in the given list.
export fn ltrim(in: []u8, trim: u8...) []u8 = {
	let i = 0z;
	for (i < len(in) && contains(trim, in[i]); i+= 1) void;
	return in[i..];
};

// Returns a slice (borrowed from given input slice) after trimming off of
// the end of the input slice the bytes in the given list.
export fn rtrim(in: []u8, trim: u8...) []u8 = {
	let i = len(in) - 1;
	for (i < len(in) && contains(trim, in[i]); i -= 1) void;
	return in[..i + 1];
};

// Returns a slice (borrowed from given input slice) after trimming off of
// the both ends of the input slice the bytes in the given list.
export fn trim(in: []u8, trim: u8...) []u8 = ltrim(rtrim(in, trim...), trim...);

@test fn trim() void = {
	assert(equal(trim([0, 1, 2, 3, 5, 0], 0), [1, 2, 3, 5]));
	assert(equal(trim([1, 2, 3, 5], 0), [1, 2, 3, 5]));
	assert(equal(trim([0, 0, 0], 0), []));
	assert(equal(trim([0, 5, 0], 5), [0, 5, 0]));
	assert(equal(trim([], 0), []));
};
