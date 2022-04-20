use bytes;
use crypto::cipher;
use rt;

def RKLEN_128: size = 176;
def RKLEN_192: size = 208;
def RKLEN_256: size = 240;

export type x86ni_block = struct {
	cipher::block,
	enc_rk: [RKLEN_256]u8,
	dec_rk: [RKLEN_256]u8,
	rklen: u8,
};

// Checks if the native AES interface is available.
export fn x86ni_available() bool = {
	return rt::cpuid_hasflags(0, rt::cpuid_ecxflags::AES);
};

// Returns a native AES [[crypto::cipher::block]] implementation for x86_64
// CPUs supporting AES-NI.
//
// The caller must call [[x86ni_init]] to add a key to the cipher before using
// the cipher, and must call [[crypto::cipher::finish]] when they are finished
// using the cipher to securely erase any secret data stored in the cipher
// state.
export fn x86ni() x86ni_block = {
	return x86ni_block {
		blocksz = BLOCKSIZE,
		nparallel = CT64_NPARALLEL,
		encrypt = &x86ni_encrypt,
		decrypt = &x86ni_decrypt,
		finish = &x86ni_finish,
		...
	};
};

export fn x86ni_init(b: *x86ni_block, key: []u8) void = {
	assert(len(key) == 16 || len(key) == 24 || len(key) == 32,
		"Invalid aes key length");

	b.rklen = x86ni_keyexp(key[..], b.enc_rk[..], b.dec_rk[..]);
};

fn x86ni_encrypt(block: *cipher::block, dest: []u8, src: []u8) void = {
	let b = block: *x86ni_block;
	x86ni_asencrypt(b.enc_rk[..b.rklen], dest, src);
};

fn x86ni_decrypt(block: *cipher::block, dest: []u8, src: []u8) void = {
	let b = block: *x86ni_block;
	x86ni_asdecrypt(b.dec_rk[..b.rklen], dest, src);
};

fn x86ni_finish(block: *cipher::block) void = {
	let b = block: *x86ni_block;
	bytes::zero(b.enc_rk[..]);
	bytes::zero(b.dec_rk[..]);
};

// Expands encryption and decryption key and returns the size of the round keys.
export fn x86ni_keyexp(key: []u8, enc_rk: []u8, dec_rk: []u8) u8;
export fn x86ni_asencrypt(key_exp: []u8, dest: []u8, src: []u8) void;
export fn x86ni_asdecrypt(key_exp: []u8, dest: []u8, src: []u8) void;

