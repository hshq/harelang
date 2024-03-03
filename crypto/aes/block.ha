// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::cipher;

// The block size used by the AES algorithm.
export def BLOCKSZ: size = 16;

// Size of the buffer used for [[crypto::cipher::cbc_encryptor]] and
// [[crypto::cipher::cbc_decryptor]].
export def CBC_BUFSZ: size = BLOCKSZ * 2;

// Size of the buffer used for [[crypto::cipher::ctr]].
export def CTR_BUFSZ: size = BLOCKSZ * (MAXNPARALLEL + 1);

export type block = struct {
	vtable: cipher::block,
	rounds: u32,
	expkey: [MAXEXPKEYSZ]u8,
};

// Returns an AES [[crypto::cipher::block]] cipher implementation that has
// hardware support if possible. Check [[hwsupport]] to see if it is available.
//
// The caller must call [[init]] to add a key to the cipher before using
// the cipher, and must call [[crypto::cipher::finish]] when they are finished
// using the cipher to securely erase any secret data stored in the cipher
// state.
export fn aes() block = block {
	vtable = rtvtable,
	...
};


let hwsup: bool = false;

// Checks whether hardware AES support is available.
export fn hwsupport() bool = hwsup;

type initfunc = fn(b: *block, key: []u8) void;

// Initializes the AES block with an encryption key.
export fn init(b: *block, key: []u8) void = initfuncptr(b, key);

fn block_finish(b: *cipher::block) void = {
	let b = b: *block;
	bytes::zero(b.expkey);
};
