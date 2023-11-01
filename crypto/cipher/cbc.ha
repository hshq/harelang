// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::math;

export type cbc_mode = struct {
	b: *block,
	encrypt: bool,
	carry: []u8,
	carrybuf: []u8,
};

// Creates a cipher block chaining (CBC) mode encryptor.
//
// The user must supply an initialization vector (IV) equal in length to the
// block size of the underlying [[block]] cipher, and a temporary state buffer
// whose size is equal to the block size times two. The module providing the
// underlying block cipher usually provides constants which define the lengths
// of these buffers for static allocation.
export fn cbc_encryptor(b: *block, iv: []u8, buf: []u8) cbc_mode = {
	assert(len(iv) == blocksz(b),
		"len(iv) must be the same as the block size");
	assert(len(buf) == blocksz(b) * 2,
		"buffer needs to be two times of the block size");

	const bsz = blocksz(b);
	let carry = buf[0..bsz];
	carry[..] = iv[..];

	return cbc_mode {
		b = b,
		encrypt = true,
		carry = carry,
		carrybuf = buf[bsz..],
	};
};

// Creates a cipher block chaining (CBC) mode decryptor.
//
// The user must supply an initialization vector (IV) equal in length to the
// block size of the underlying [[block]] cipher, and a temporary state buffer
// whose size is equal to the block size times two. The module providing the
// underlying block cipher usually provides constants which define the lengths
// of these buffers for static allocation.
export fn cbc_decryptor(b: *block, iv: []u8, buf: []u8) cbc_mode = {
	assert(len(iv) == blocksz(b),
		"len(iv) must be the same as block length sz");
	assert(len(buf) == blocksz(b) * 2,
		"buffer needs to be two times of the block size");

	const bsz = blocksz(b);
	let carry = buf[0..bsz];
	carry[..] = iv[..];

	return cbc_mode {
		b = b,
		encrypt = false,
		carry = carry,
		carrybuf = buf[bsz..],
	};
};

// Encrypts given blocks with a length that is a multiple of the block size.
// In place encryption only works if dest and src point exactly at the
// same range.
export fn cbc_encrypt(c: *cbc_mode, dest: []u8, src: []u8) void = {
	const sz = blocksz(c.b);
	assert(c.encrypt);
	assert(len(dest) % sz == 0 && len(src) == len(dest),
		"size of dest and src needs to match and be a multiple of block size");

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		math::xor(dest[i..eb], src[i..eb], c.carry);
		encrypt(c.b, dest[i..eb], dest[i..eb]);
		c.carry[..] = dest[i..eb];
	};
};

// Decrypts given blocks with a length that is a multiple of the block size.
// In place decryption only works if dest and src point exactly at the
// same range.
export fn cbc_decrypt(c: *cbc_mode, dest: []u8, src: []u8) void = {
	const sz = blocksz(c.b);
	assert(!c.encrypt);
	assert(len(dest) % sz == 0 && len(src) == len(dest),
		"size of dest and src needs to match and be a multiple of block size");

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		c.carrybuf[..] = c.carry[..];
		c.carry[..] = src[i..eb];
		decrypt(c.b, dest[i..eb], src[i..eb]);
		math::xor(dest[i..eb], dest[i..eb], c.carrybuf);
	};
};
