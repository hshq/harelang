// License: MPL-2.0
// (c) 2021 Steven Guikal <void@fluix.dev>

// State for a pseudorandom number generator.
export type random = u64;

// Initializes a pseudorandom number generator with a given seed. This seed will
// yield the same sequence of psuedo-random numbers if used again.
export fn init(seed: u64) random = seed;

// Returns a psuedo-random 64-bit unsigned integer.
export fn next(r: *random) u64 = {
	// SplitMix64
	*r += 0x9e3779b97f4a7c15;
	*r = (*r ^ *r >> 30) * 0xbf58476d1ce4e5b9;
	*r = (*r ^ *r >> 27) * 0x94d049bb133111eb;
	return *r ^ *r >> 31;
};

@test fn rng() void = {
	let r = init(0);
	let expected: [_]u64 = [
		16294208416658607535,
		15501543990041496116,
		15737388954706874752,
		15091258616627000950,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		assert(next(&r) == expected[i]);
	};
};
