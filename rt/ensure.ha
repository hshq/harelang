export type slice = struct {
	data: *void,
	length: size,
	capacity: size,
};

export fn ensure(s: *slice, membsz: size, length: size) void = {
	let cap = s.capacity;
	for (cap < length) {
		assert(cap >= s.capacity, "slice out of memory (overflow)");
		if (cap == 0) {
			cap = length;
		} else {
			cap *= 2;
		};
	};
	s.capacity = cap;
	let data = realloc(s.data, s.capacity * membsz);
	assert(data != null);
	s.data = data;
};
