use crypto::math;

export type cbc_mode = struct {
	b: *block,
	encrypt: bool,
	carry: []u8,
	carrybuf: []u8,
};

// Creates a cipher block chaining mode encryptor. The encryptor will keep its 
// state, so data can be encrypted using multiple cbc_encrypt calls.  The size 
// of the buffer depends on the block cipher. Use [[crypto::aes::CBC_BUFSIZE]] 
// for the stdlib AES implementation.
export fn cbc_encryptor(b: *block, iv: []u8, buf: []u8) cbc_mode = {
	assert(len(iv) == sz(b), "len(iv) must be the same as the block size");
	assert(len(buf) == sz(b) * 2, 
		"buffer needs to be two times of the block size");

	let bsz = sz(b);
	let carry = buf[0..bsz];
	carry[..] = iv[..];

	return cbc_mode {
		b = b,
		encrypt = true,
		carry = carry,
		carrybuf = buf[bsz..],
	};
};

// Creates a cipher block chaining mode decryptor. The decryptor will keep its 
// state, so data can be encrypted using multiple cbc_decrypt calls.  The size 
// of the buffer depends on the block cipher. Use [[crypto::aes::CBC_BUFSIZE]] 
// for the stdlib AES implementation.
export fn cbc_decryptor(b: *block, iv: []u8, buf: []u8) cbc_mode = {
	assert(len(iv) == sz(b), "len(iv) must be the same as block length sz");
	assert(len(buf) == sz(b) * 2, 
		"buffer needs to be two times of the block size");

	let bsz = sz(b);
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
	let sz = sz(c.b);

	assert(c.encrypt);
	assert(len(dest) % sz == 0 && len(src) == len(dest),
		"size of dest and src needs to match and be a multiple of block size");

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		crypto::math::xor(dest[i..eb], src[i..eb], c.carry);
		encrypt(c.b, dest[i..eb], dest[i..eb]);
		c.carry[..] = dest[i..eb];
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

	for (let i = 0z; i < len(dest); i += sz) {
		let eb = i + sz;
		c.carrybuf[..] = c.carry[..];
		c.carry[..] = src[i..eb];
		decrypt(c.b, dest[i..eb], src[i..eb]);
		crypto::math::xor(dest[i..eb], dest[i..eb], c.carrybuf);
	};
};
