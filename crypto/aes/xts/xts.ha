// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::aes;
use crypto::cipher;

export type block = struct {
	b1: aes::block,
	b2: aes::block,
	x: [aes::BLOCKSZ]u8,
};

// Creates a AES-XTS instance. Must be initialized with [[init]] and always be
// finished using [[finish]] to erase sensitive state from memory.
export fn xts() block = block {
	b1 = aes::aes(),
	b2 = aes::aes(),
	...
};

// Initializes the AES-XTS instance. The key length must be 64, 48, or 32 bytes
// (the size of two valid AES keys).
export fn init(b: *block, key: []u8) void = {
	assert(len(key) == 64 || len(key) == 48 || len(key) == 32,
		"invalid key size");
	let sep: size = len(key) / 2;

	aes::init(&b.b1, key[..sep]);
	aes::init(&b.b2, key[sep..]);
};

def GF_128_FDBK: u8 = 0x87;

// Encrypts a block given its 'sector' number. The block must be a multiple of
// [[crypto::aes::BLOCKSZ]] (16 bytes) in length.
export fn encrypt(b: *block, dest: []u8, src: []u8, sector: u64) void = {
	assert(len(src) == len(dest) && len(src) % aes::BLOCKSZ == 0);

	let tweak: [aes::BLOCKSZ]u8 = [0...];
	let carryin: u8 = 0;
	let carryout: u8 = 0;

	for (let j = 0z; j < len(tweak); j += 1) {
		tweak[j] = (sector & 0xFF): u8;
		sector >>= 8;
	};

	cipher::encrypt(&b.b2, tweak, tweak);

	let i = 0z;
	for (i + aes::BLOCKSZ <= len(src); i += aes::BLOCKSZ) {
		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			b.x[j] = src[i + j] ^ tweak[j];
		};

		cipher::encrypt(&b.b1, b.x, b.x);

		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			dest[i + j] = b.x[j] ^ tweak[j];
		};

		// multiply primitive
		carryin = 0;
		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			carryout = (tweak[j] >> 7) & 1;
			tweak[j] = ((tweak[j] << 1) + carryin) & 0xff;
			carryin = carryout;
		};

		if (carryout != 0) {
			tweak[0] ^= GF_128_FDBK;
		};
	};
};

// Decrypts a block given its 'sector' number.
export fn decrypt(b: *block, dest: []u8, src: []u8, sector: u64) void = {
	assert(len(src) == len(dest) && len(src) % aes::BLOCKSZ == 0);

	let tweak: [aes::BLOCKSZ]u8 = [0...];
	let carryin: u8 = 0;
	let carryout: u8 = 0;

	for (let j = 0z; j < len(tweak); j += 1) {
		tweak[j] = (sector & 0xFF): u8;
		sector >>= 8;
	};

	cipher::encrypt(&b.b2, tweak, tweak);

	let i = 0z;
	for (i + aes::BLOCKSZ <= len(src); i += aes::BLOCKSZ) {
		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			b.x[j] = src[i + j] ^ tweak[j];
		};

		cipher::decrypt(&b.b1, b.x, b.x);

		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			dest[i + j] = b.x[j] ^ tweak[j];
		};


		// multiply primitive
		carryin = 0;
		for (let j = 0z; j < aes::BLOCKSZ; j += 1) {
			carryout = (tweak[j] >> 7) & 1;
			tweak[j] = ((tweak[j] << 1) + carryin) & 0xff;
			carryin = carryout;
		};

		if (carryout != 0) {
			tweak[0] ^= GF_128_FDBK;
		};
	};
};

// Clears the sensible data of AES-XTS instance off the memory.
export fn finish(b: *block) void = {
	cipher::finish(&b.b1);
	cipher::finish(&b.b2);
	bytes::zero(b.x);
};
