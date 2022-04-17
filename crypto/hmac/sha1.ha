// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use bytes;
use crypto::mac;
use crypto::sha1;
use hash;
use io;

export type sha1state = struct {
	mac::mac,
	h: sha1::state,
	keypad: [sha1::BLOCKSIZE]u8,
};

// Creates a [[crypto::mac::mac]] that computes an HMAC with given 'key' using
// SHA1 as underlying hash function.
//
// The caller must take extra care to call [[crypto::mac::finish]] when they are
// finished using the MAC function, which, in addition to freeing state
// associated with the MAC, will securely erase state which contains secret
// information.
export fn sha1(key: []u8) sha1state = {
	let s = sha1state {
		h = sha1::sha1(),
		sz = sha1::SIZE,
		bsz = sha1::BLOCKSIZE,
		writer = &sha1write,
		sum = &sha1sum,
		finish = &sha1finish,
		...
	};

	init(&s.h, key, s.keypad);
	return s;
};

fn sha1write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let hm = st: *sha1state;
	return hash::write(&hm.h, buf);
};

fn sha1sum(mac: *mac::mac, dest: []u8) void = {
	let hm = mac: *sha1state;
	sum(&hm.h, hm.keypad, dest);
};

fn sha1finish(mac: *mac::mac) void = {
	let hm = mac: *sha1state;
	bytes::zero(hm.keypad);
	io::close(&hm.h);
};