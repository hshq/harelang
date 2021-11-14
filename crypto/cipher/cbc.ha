use bytes;
use crypto::math;

export type cbc_mode = struct {
	b: *block,
	encrypt: bool,
	carry: []u8,
};

// Creates a cipher block chaining mode encryptor. The encryptor will
// keep its state, so data can be encrypted using multiple cbc_encrypt calls.
// Needs to be finished with [[crypto::cipher::cbc_finish]]
export fn cbc_encryptor(b: *block, iv: []u8) cbc_mode = {
	assert(len(iv) == sz(b), "len(iv) must be the same as block length sz");

	return cbc_mode {
		b = b,
		encrypt = true,
		carry = alloc(iv),
	};
};

// Creates a cipher block chaining mode decryptor. The decryptor will
// keep its state, so data can be encrypted using multiple cbc_decrypt calls.
// Needs to be finished with [[crypto::cipher::cbc_finish]]
export fn cbc_decryptor(b: *block, iv: []u8) cbc_mode = {
	assert(len(iv) == sz(b), "len(iv) must be the same as block length sz");

	return cbc_mode {
		b = b,
		encrypt = false,
		carry = alloc(iv),
	};
};

// Frees a cipher block chaining mode encryptor or decryptor
export fn cbc_finish(c: *cbc_mode) void = {
	free(c.carry);
};

// Encrypts given blocks with a length that is a multiple of the block size.
// In place encryption only works if dest and src point exactly at the
// same range.
export fn cbc_encrypt(c: *cbc_mode, dest: []u8, src: []u8) void = {
	let sz = sz(c.b);

	assert(c.encrypt);
	assert(len(dest) % sz == 0 && len(src) == len(dest),
		"size of dest and src needs to match and be a multiple of block size");

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		crypto::math::xor(dest[i..eb], src[i..eb], c.carry);
		encrypt(c.b, dest[i..eb], dest[i..eb]);
		bytes::copy(c.carry, dest[i..eb]);
	};
};

// Decrypts given blocks with a length that is a multiple of the block size.
// In place decryption only works if dest and src point exactly at the
// same range.
export fn cbc_decrypt(c: *cbc_mode, dest: []u8, src: []u8) void = {
	let sz = sz(c.b);

	assert(!c.encrypt);
	assert(len(dest) % sz == 0 && len(src) == len(dest),
		"size of dest and src needs to match and be a multiple of block size");

	let carry = alloc(c.carry);
	defer free(carry);

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		bytes::copy(carry, c.carry);
		bytes::copy(c.carry, src[i..eb]);
		decrypt(c.b, dest[i..eb], src[i..eb]);
		crypto::math::xor(dest[i..eb], dest[i..eb], carry);
	};
};
