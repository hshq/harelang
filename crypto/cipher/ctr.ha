// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use crypto::math::{xor};
use io;

// A counter mode (CTR) stream.
export type ctr_stream = struct {
	xorstream,
	b: *block,
	counter: []u8,
	xorbuf: []u8,
	xorused: size,
};

// Creates a counter mode (CTR) cipher stream which can be used for encryption
// (by encrypting writes to the underlying handle) or decryption (or by
// decrypting reads from the underlying handle), but not both.
//
// The user must supply an initialization vector (IV) equal in length to the
// block size of the underlying [[block]] cipher, and a temporary state buffer
// whose size is equal to the block size times two. The module providing the
// underlying block cipher usually provides constants which define the lengths
// of these buffers for static allocation.
//
// The user must call [[io::close]] when they are done using the stream to
// securely erase secret information stored in the stream state. This will also
// finish the underlying [[block]] cipher.
export fn ctr(h: io::handle, b: *block, iv: []u8, buf: []u8) ctr_stream = {
	assert(len(iv) == blocksz(b), "iv is of invalid block size");
	assert(len(buf) >= blocksz(b) * 2, "buf must be at least 2 * blocksize");

	const bsz = blocksz(b);

	// one buf block is used for the counter
	let counter = buf[0..bsz];

	// the remaining space is used to store the key stream. It needs
	// to be at least the size of one block and ideally the size of
	// nparallel(b) times the block size. A bigger buffer than the latter
	// option is of no use.
	let xorbuf = buf[bsz..];

	counter[..] = iv[..];

	// cap the buffer to a multiple of bsz.
	let maxxorbufsz = blocksz(b) * nparallel(b);
	const xorbufsz = if (len(xorbuf) < maxxorbufsz) {
		yield len(xorbuf) - len(xorbuf) % blocksz(b);
	} else {
		yield maxxorbufsz;
	};

	let s = ctr_stream {
		stream = &xorstream_vtable,
		h = h,
		keybuf = &ctr_keybuf,
		advance = &ctr_advance,
		finish = &ctr_finish,

		b = b,
		counter = counter,
		xorbuf = xorbuf[..xorbufsz],
		// mark all as used to force fill xorbuf
		xorused = xorbufsz,
		...
	};
	return s;
};

fn fill_xorbuf(ctr: *ctr_stream) void = {
	const bsz = blocksz(ctr.b);

	// Write and increment the counter to each available block
	for (let i = 0z; i < len(ctr.xorbuf) / bsz; i += 1) {
		ctr.xorbuf[i * bsz..(i * bsz + bsz)] = ctr.counter[0..bsz];

		for (let j = len(ctr.counter); j > 0; j -= 1) {
			ctr.counter[j - 1] += 1;
			if (ctr.counter[j - 1] != 0) {
				break;
			};
		};
	};

	encrypt(ctr.b, ctr.xorbuf, ctr.xorbuf);
	ctr.xorused = 0;
};

fn ctr_keybuf(s: *xorstream) []u8 = {
	let ctr = s: *ctr_stream;
	if (ctr.xorused >= len(ctr.xorbuf)) {
		fill_xorbuf(ctr);
	};
	return ctr.xorbuf[ctr.xorused..];
};

fn ctr_advance(s: *xorstream, n: size) void = {
	let ctr = s: *ctr_stream;

	// fill_xorbuf could be smarter, to skip multiple blocks at once.
	// It's of no use, since xorstream doesn't support skipping an arbritary
	// number of blocks.
	assert(n <= len(ctr.xorbuf));

	ctr.xorused += n;
};

fn ctr_finish(s: *xorstream) void = {
	let ctr = s: *ctr_stream;
	bytes::zero(ctr.xorbuf);
	finish(ctr.b);
};
