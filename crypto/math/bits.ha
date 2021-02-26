// crypto::math provides constant-time mathematical operations useful for
// cryptographic algorithms.

// Rotates a 32-bit unsigned integer left by k bits. k may be negative to rotate
// right instead, or see [rotr32].
export fn rotl32(x: u32, k: int) u32 = {
	const n = 32u32;
	const s = k: u32 & (n - 1);
	return x << s | x >> (n - s);
};

// Rotates a 32-bit unsigned integer right by k bits. k may be negative to
// rotate left instead, or see [rotl32].
export fn rotr32(x: u32, k: int) u32 = rotl32(x, -k);

@test fn lrot32() void = {
	let a = 0b11110000111100001111000011110000u32;
	assert(rotl32(a, 2) == 0b11000011110000111100001111000011u32);
	assert(rotl32(a, -2) == 0b00111100001111000011110000111100u32);
	assert(rotl32(a, 32) == 0b11110000111100001111000011110000u32);
	assert(rotl32(a, 64) == 0b11110000111100001111000011110000u32);
};
