// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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

// Returns a pseudo-random 32-bit unsigned integer in the half-open interval
// [0,n). n must be greater than zero.
export fn u32n(r: *random, n: u32) u32 = {
	// https://lemire.me/blog/2016/06/27/a-fast-alternative-to-the-modulo-reduction/
	// https://lemire.me/blog/2016/06/30/fast-random-shuffling/
	assert(n != 0);
	let prod = next(r): u32: u64 * n: u64;
	let leftover = prod: u32;
	if (leftover < n) {
		let thresh = -n % n;
		for (leftover < thresh) {
			prod = next(r): u32: u64 * n: u64;
			leftover = prod: u32;
		};
	};
	return (prod >> 32): u32;
};

// Returns a pseudo-random 64-bit unsigned integer in the half-open interval
// [0,n). n must be greater than zero.
export fn u64n(r: *random, n: u64) u64 = {
	assert(n != 0);
	// Powers of 2 can be handled more efficiently
	if (n & n - 1 == 0) return next(r) & n - 1;
	// Equivalent to 2^64 - 1 - 2^64 % n
	let max = -1 - -n % n;
	let out = next(r);
	for (out > max) out = next(r);
	return out % n;
};

// Returns a pseudo-random 64-bit floating-point number in the interval
// [0.0, 1.0)
export fn f64rand(r: *random) f64 = {
	// 1.0 x 2^-53
	const d: f64 = 1.1102230246251565e-16;
	// Take the upper 53 bits
	let n = next(r) >> 11;

	return d * n: f64;
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

	for (let i = 0z; i < 1000; i += 1) {
		assert(u32n(&r, 3) < 3);
	};

	for (let i = 0z; i < 1000; i += 1) {
		assert(u64n(&r, 3) < 3);
	};
	for (let i = 0z; i < 1000; i += 1) {
		// Powers of 2 have a separate codepath
		assert(u64n(&r, 2) < 2);
	};
	for (let i = 0z; i < 1000; i += 1) {
		assert(f64rand(&r) < 1.0);
	};
};
