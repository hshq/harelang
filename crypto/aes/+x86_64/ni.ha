// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::cipher;
use rt;

def EXPKEYLEN128: size = 176;
def EXPKEYLEN192: size = 208;
def EXPKEYLEN256: size = 240;

def X86NI_EXPKEYSZ: size = 480;

const x86ni_vtable: cipher::blockvtable = cipher::blockvtable {
	blocksz = BLOCKSZ,
	nparallel = 1,
	encrypt = &x86ni_encrypt,
	decrypt = &x86ni_decrypt,
	finish = &block_finish,
};

// Checks if the native AES interface is available.
fn x86ni_available() bool = {
	return rt::cpuid_hasflags(0, rt::cpuid_ecxflag::AES | rt::cpuid_ecxflag::AVX);
};

// Returns a native AES [[crypto::cipher::block]] implementation for x86_64
// CPUs supporting AES-NI.
//
// The caller must call [[x86ni_init]] to add a key to the cipher before using
// the cipher, and must call [[crypto::cipher::finish]] when they are finished
// using the cipher to securely erase any secret data stored in the cipher
// state.
fn x86ni() block = {
	return block {
		vtable = &x86ni_vtable,
		...
	};
};

fn x86ni_init(b: *block, key: []u8) void = {
	assert(len(key) == 16 || len(key) == 24 || len(key) == 32,
		"Invalid aes key length");

	let enc = b.expkey[..EXPKEYLEN256];
	let dec = b.expkey[EXPKEYLEN256..];
	const expkeylen = x86ni_keyexp(key[..], enc, dec);
	b.rounds = (expkeylen >> 4) - 1;
};

fn x86ni_encrypt(b: *cipher::block, dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src) && len(dest) % BLOCKSZ == 0);
	let b = b: *block;
	const expkeylen = (b.rounds + 1) << 4;
	let enc = b.expkey[..expkeylen];

	// XXX loop could be done in assembly
	for (len(src) > 0) {
		x86ni_asencrypt(enc, dest, src);
		src = src[BLOCKSZ..];
		dest = dest[BLOCKSZ..];
	};
};

fn x86ni_decrypt(b: *cipher::block, dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src) && len(dest) % BLOCKSZ == 0);
	let b = b: *block;
	const expkeylen = (b.rounds + 1) << 4;
	let dec = b.expkey[EXPKEYLEN256..];

	// XXX loop could be done in assembly
	for (len(src) > 0) {
		x86ni_asdecrypt(dec[..expkeylen], dest, src);
		src = src[BLOCKSZ..];
		dest = dest[BLOCKSZ..];
	};
};

// Expands encryption and decryption key and returns the size of the round keys.
fn x86ni_keyexp(key: []u8, enc_rk: []u8, dec_rk: []u8) u8;
fn x86ni_asencrypt(key_exp: []u8, dest: []u8, src: []u8) void;
fn x86ni_asdecrypt(key_exp: []u8, dest: []u8, src: []u8) void;
