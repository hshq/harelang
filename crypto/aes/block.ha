// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use bytes;
use crypto::cipher;

// The block size used by the AES algorithm.
export def BLOCKSIZE: size = 16;

export type block = struct {
	vtable: cipher::block,
	rounds: u32,
	expkey: [MAXEXPKEYSIZE]u8,
};

fn block_finish(b: *cipher::block) void = {
	let b = b: *block;
	bytes::zero(b.expkey);
};
