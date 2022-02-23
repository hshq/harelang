// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use bytes;
use crypto::mac;
use crypto::sha256;
use hash;
use io;

export type sha256state = struct {
	mac::mac,
	h: sha256::state,
	keypad: [sha256::BLOCKSIZE]u8,
};

// Creates a [[crypto::mac::mac]] that computes an HMAC with given 'key' using
// SHA256 as underlying hash function.
//
// The caller must take extra care to call [[mac::finish]] when they are
// finished using the MAC function, which, in addition to freeing state
// associated with the MAC, will securely erase state which contains secret
// information.
export fn sha256(key: []u8) sha256state = {
	let s = sha256state {
		h = sha256::sha256(),
		sz = sha256::SIZE,
		bsz = sha256::BLOCKSIZE,
		writer = &sha256write,
		sum = &sha256sum,
		finish = &sha256finish,
		...
	};

	init(&s.h, key, s.keypad);
	return s;
};

fn sha256write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let hm = st: *sha256state;
	return hash::write(&hm.h, buf);
};

fn sha256sum(mac: *mac::mac, dest: []u8) void = {
	let hm = mac: *sha256state;
	sum(&hm.h, hm.keypad, dest);
};

fn sha256finish(mac: *mac::mac) void = {
	let hm = mac: *sha256state;
	bytes::zero(hm.keypad);
	io::close(&hm.h);
};
