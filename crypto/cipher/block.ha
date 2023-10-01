// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// An abstract interface for implementing block ciphers.
export type blockvtable = struct {
	blocksz: size,

	nparallel: size,

	encrypt: *fn(b: *block, dest: []u8, src: []u8) void,
	decrypt: *fn(b: *block, dest: []u8, src: []u8) void,
	finish: *fn(b: *block) void,
};

export type block = *blockvtable;

// Returns the block size in bytes for a [[block]] cipher.
export fn blocksz(b: *block) size = b.blocksz;

// Returns the number of blocks that can be processed at once for a [[block]]
// cipher.
export fn nparallel(b: *block) size = b.nparallel;

// Encrypt up to [[nparallel]] blocks from 'src' and writes to 'dest'.
export fn encrypt(b: *block, dest: []u8, src: []u8) void =
	b.encrypt(b, dest, src);

// Decrypt up to [[nparallel]] blocks from 'src' and writes to 'dest'.
export fn decrypt(b: *block, dest: []u8, src: []u8) void =
	b.decrypt(b, dest, src);
