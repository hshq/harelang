export type slice = struct {
	data: *void,
	length: size,
	capacity: size,
};

export fn ensure(s: *slice, membsz: size, length: size) void = {
	// TODO: make sure length * membsz < SIZE_MAX
	for (s.capacity < length) {
		s.capacity *= 2z;
	};
	let data = realloc(s.data, s.capacity * membsz);
	assert(data != null: nullable *void);
	s.data = data;
};
