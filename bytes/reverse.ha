// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Reverses a slice of bytes.
export fn reverse(b: []u8) void = {
	if (len(b) == 0) {
		return;
	};
	for (let s = 0z, e = len(b) - 1; s < e) {
		let x = b[s];
		b[s] = b[e];
		b[e] = x;
		s += 1;
		e -= 1;
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
