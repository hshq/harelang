// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type slice = struct {
	data: nullable *opaque,
	length: size,
	capacity: size,
};

export fn ensure(s: *slice, membsz: size) void = {
	let capacity = s.capacity;
	if (capacity >= s.length) {
		return;
	};
	for (capacity < s.length) {
		assert(capacity >= s.capacity, "slice out of memory (overflow)");
		if (capacity == 0) {
			capacity = s.length;
		} else {
			capacity *= 2;
		};
	};
	s.capacity = capacity;
	const data = realloc(s.data, s.capacity * membsz);
	assert(data != null || s.capacity * membsz == 0);
	s.data = data;
};

export fn unensure(s: *slice, membsz: size) void = {
	let capacity = s.capacity;
	for (capacity > s.length) {
		capacity /= 2;
	};
	capacity *= 2;
	s.capacity = capacity;
	const data = realloc(s.data, s.capacity * membsz);
	assert(data != null || s.capacity * membsz == 0);
	s.data = data;
};
