// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;


// Rotates a 32-bit unsigned integer left by k bits. k may be negative to rotate
// right instead, or see [[rotr32]].
export fn rotl32(x: u32, k: int) u32 = {
	const n = 32u32;
	const s = k: u32 & (n - 1);
	return x << s | x >> (n - s);
};

// Rotates a 32-bit unsigned integer right by k bits. k may be negative to
// rotate left instead, or see [[rotl32]].
export fn rotr32(x: u32, k: int) u32 = rotl32(x, -k);

@test fn lrot32() void = {
	let a = 0b11110000111100001111000011110000u32;
	assert(rotl32(a, 2) == 0b11000011110000111100001111000011u32);
	assert(rotl32(a, -2) == 0b00111100001111000011110000111100u32);
	assert(rotl32(a, 32) == 0b11110000111100001111000011110000u32);
	assert(rotl32(a, 64) == 0b11110000111100001111000011110000u32);
};

// Rotates a 64-bit unsigned integer left by k bits. k may be negative to rotate
// right instead, or see [[rotr64]].
export fn rotl64(x: u64, k: int) u64 = {
	const n = 64u64;
	const s = k: u64 & (n - 1);
	return x << s | x >> (n - s);
};

// Rotates a 64-bit unsigned integer right by k bits. k may be negative to rotate
// left instead, or see [[rotl64]].
export fn rotr64(x: u64, k: int) u64 = rotl64(x, -k);

@test fn lrot64() void = {
	let a = 1u64;
	assert(rotl64(a, 1) == 0b10);
	assert(rotl64(a, -1) == 0b1000000000000000000000000000000000000000000000000000000000000000);
	assert(rotl64(a, 39) == (1u64 << 39));

	let a = 0b1111000011110000111100001111000011110000111100001111000011110000u64;
	assert(rotl64(a, 64) == a);
	assert(rotl64(a, 0) == a);
	assert(rotl64(a, 2) == 0b1100001111000011110000111100001111000011110000111100001111000011u64);
	assert(rotl64(a, -2) == 0b0011110000111100001111000011110000111100001111000011110000111100u64);

};

// Stores the xor of 'a' and 'b' into 'dest'. All parameters must have the same
// length. 'dest' may be the same slice as 'a' and/or 'b'.
export fn xor(dest: []u8, a: []u8, b: []u8) void = {
	assert(len(dest) == len(a) && len(dest) == len(b),
		"dest, a and b must have the same length");

	for (let i = 0z; i < len(dest); i += 1) {
		dest[i] = a[i] ^ b[i];
	};
};

// Compare two byte slices in constant time.
//
// Returns 1 if the two slices have the same contents, 0 otherwise.
export fn eqslice(x: []u8, y: []u8) int = {
	assert(len(x) == len(y), "slices must have the same length");
	let v: u8 = 0;
	for (let i = 0z; i < len(x); i += 1) {
		v |= x[i] ^ y[i];
	};
	return equ8(v, 0);
};

@test fn eqslice() void = {
	assert(eqslice([], []) == 1);
	assert(eqslice([0], [0]) == 1);
	assert(eqslice([1], [0]) == 0);
	assert(eqslice([1, 0], [0, 0]) == 0);
	assert(eqslice([0, 0], [0, 0]) == 1);

	assert(eqslice([0x12, 0xAB], [0x12, 0xAB]) == 1);
	assert(eqslice([0x12, 0xAB], [0x12, 0xAC]) == 0);
	assert(eqslice([0x12, 0xAB], [0x11, 0xAB]) == 0);
};

// Compare two bytes in constant time. Returns 1 if the bytes are the same
// value, 0 otherwise.
export fn equ8(x: u8, y: u8) int = ((((x ^ y) : u32) - 1) >> 31) : int;

// Returns x if ctl == 1 and y if ctl == 0.
export fn muxu32(ctl: u32, x: u32, y: u32) u32 = y ^ ((-(ctl: i32)): u32 & (x ^ y));

@test fn muxu32() void = {
	assert(muxu32(1, 0x4, 0xff) == 0x4);
	assert(muxu32(0, 0x4, 0xff) == 0xff);
};

// Negates first bit.
export fn notu32(x: u32) u32 = x ^ 1;

// Compares 'x' and 'y'. Returns 1 if they are equal or 0 otherwise.
export fn equ32(x: u32, y: u32) u32 = {
	let q = x ^ y;
	return ((q | -(q: i32): u32) >> 31) ^ 1;
};

@test fn equ32() void = {
	assert(equ32(0x4f, 0x4f) == 1);
	assert(equ32(0x4f, 0x0) == 0);
	assert(equ32(0x2, 0x6) == 0);
};

// Returns 1 if 'x' is zero or 0 if not.
export fn eq0u32(x: u32) u32 = {
	return ~(x | -x) >> 31;
};

@test fn eq0u32() void = {
	assert(eq0u32(0) == 1);
	assert(eq0u32(1) == 0);
	assert(eq0u32(0x1234) == 0);
	assert(eq0u32(types::U32_MAX) == 0);
};

// Returns 1 if x != y and 0 otherwise.
export fn nequ32(x: u32, y: u32) u32 = {
	let q = x ^ y;
	return (q | -(q: i32): u32) >> 31;
};

// Returns 1 if x > y and 0 otherwise.
export fn gtu32(x: u32, y: u32) u32 = {
	let z: u32 = y - x;
	return (z ^ ((x ^ y) & (x ^ z))) >> 31;
};

@test fn gtu32() void = {
	assert(gtu32(1, 0) == 1);
	assert(gtu32(0, 1) == 0);
	assert(gtu32(0, 0) == 0);

	assert(gtu32(0xf3, 0xf2) == 1);
	assert(gtu32(0x20, 0xff) == 0);
	assert(gtu32(0x23, 0x23) == 0);
};

// Returns 1 if x >= y and 0 otherwise.
export fn geu32(x: u32, y: u32) u32 = notu32(gtu32(y, x));

// Returns 1 if x < y and 0 otherwise.
export fn ltu32(x: u32, y: u32) u32 = gtu32(y, x);

// Returns 1 if x <= y and 0 otherwise.
export fn leu32(x: u32, y: u32) u32 = notu32(gtu32(x, y));

// Compares 'x' with 'y'. Returns -1 if x < y, 0 if x == y and 1 if x > x.
export fn cmpu32(x: u32, y: u32) i32 = gtu32(x, y): i32 | -(gtu32(y, x): i32);

@test fn cmpu32() void = {
	assert(cmpu32(0, 0) == 0);
	assert(cmpu32(0x34, 0x34) == 0);

	assert(cmpu32(0x12, 0x34) == -1);
	assert(cmpu32(0x87, 0x34) == 1);
};

// Multiplies two u32 and returns result as u64.
export fn mulu32(x: u32, y: u32) u64 = x: u64 * y: u64;

// Copies 'src' to 'dest' if 'ctl' == 1
export fn ccopyu32(ctl: u32, dest: []u32, src: const []u32) void = {
	for (let i = 0z; i < len(dest); i += 1) {
		const x = src[i];
		const y = dest[i];

		dest[i] = muxu32(ctl, x, y);
	};
};
