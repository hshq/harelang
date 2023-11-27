// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Reverses a slice of bytes in place.
export fn reverse(b: []u8) void = {
	for (let i = 0z; i < len(b) / 2; i += 1) {
		let x = b[i];
		b[i] = b[len(b) - i - 1];
		b[len(b) - i - 1] = x;
	};
};

@test fn reverse() void = {
	let b: [4]u8 = [1, 3, 3, 7];
	reverse(b);
	assert(equal(b, [7, 3, 3, 1]));
	let b: [5]u8 = [1, 2, 3, 4, 5];
	reverse(b);
	assert(equal(b, [5, 4, 3, 2, 1]));
	let b: [1]u8 = [1];
	reverse(b);
	assert(equal(b, [1]));
	let b: []u8 = [];
	reverse(b);
	assert(equal(b, []));
};
