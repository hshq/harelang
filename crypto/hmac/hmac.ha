// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::mac;
use hash;
use io;

export type state = struct {
	mac::mac,
	h: *hash::hash,
	keypad: []u8,
};

const hmac_vtable: io::vtable = io::vtable {
	writer = &write,
	...
};

// Creates a [[crypto::mac::mac]] that computes an HMAC using the provided hash
// function 'h' with given 'key'. The caller must provide a 'buf' of
// [[hash::bsz]] bytes. Use the BLOCKSZ constant of the given hash function to
// allocate the memory statically.
//
// The caller must take extra care to call [[crypto::mac::finish]] when they are
// finished using the MAC function, which, in addition to freeing state
// associated with the MAC, will securely erase state which contains secret
// information.
export fn hmac(h: *hash::hash, key: const []u8, buf: []u8) state = {
	const bsz = hash::bsz(h);

	assert(len(buf) >= bsz, "buf must be at least the size of one "
		"block of the given hash function");
	let keypad = buf[..bsz];

	init(h, key, keypad);

	return state {
		h = h,
		stream = &hmac_vtable,
		sz = hash::sz(h),
		bsz = bsz,
		sum = &gensum,
		finish = &finish,
		keypad = keypad,
		...
	};
};

fn init(h: *hash::hash, key: []u8, keypad: []u8) void = {
	const bsz = hash::bsz(h);
	if (len(key) > bsz) {
		hash::write(h, key);
		hash::sum(h, keypad);
		hash::reset(h);
	} else {
		keypad[..len(key)] = key[..];
	};

	for (let i = 0z; i < bsz; i += 1) {
		keypad[i] = 0x36 ^ keypad[i];
	};

	hash::write(h, keypad);

	for (let i = 0z; i < bsz; i += 1) {
		// keypad for the outer hash is xored with 0x5c instead of 0x36
		keypad[i] = keypad[i] ^ 0x36 ^ 0x5c;
	};
};

fn write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let hm = st: *state;
	return hash::write(hm.h, buf);
};

fn sum(h: *hash::hash, keypad: []u8, dest: []u8) void = {
	hash::sum(h, dest);

	hash::reset(h);
	hash::write(h, keypad);
	hash::write(h, dest);
	hash::sum(h, dest);
};

fn gensum(mac: *mac::mac, dest: []u8) void = {
	let hm = mac: *state;
	sum(hm.h, hm.keypad, dest);
};

fn finish(mac: *mac::mac) void = {
	let hm = mac: *state;
	bytes::zero(hm.keypad);
	io::close(hm.h)!;
};
