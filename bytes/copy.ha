// Copies bytes from src to dest. dest must have the same length as src.
export fn copy(dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src),
		"Destination slice must have same length as source slice");
	for (let i = 0z; i < len(dest); i += 1z) {
		dest[i] = src[i];
	};
};
