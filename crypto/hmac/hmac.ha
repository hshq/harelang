use bytes;
use crypto::mac;
use hash;
use io;

export type state = struct {
	mac::mac,
	h: *hash::hash,
	keypad: []u8,
};

// Creates a [[crypto::mac::mac]] that computes an HMAC using the provided hash
// function 'h'.
//
// The caller must take extra care to call [[mac::finish]] when they are
// finished using the MAC function, which, in addition to freeing state
// associated with the MAC, will securely erase state which contains secret
// information.
export fn hmac(h: *hash::hash, key: []u8) state = {
	let bsz = hash::bsz(h);
	let keypad: []u8 = alloc([0...], bsz);

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

	return state {
		writer = &write,
		sum = &sum,
		finish = &finish,
		sz = hash::sz(h),
		bsz = bsz,
		h = h,
		keypad = keypad,
		...
	};
};

fn write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let hm = st: *state;
	return hash::write(hm.h, buf);
};

fn sum(mac: *mac::mac, buf: []u8) void = {
	let hm = mac: *state;

	hash::sum(hm.h, buf);

	hash::reset(hm.h);
	hash::write(hm.h, hm.keypad);
	hash::write(hm.h, buf);
	hash::sum(hm.h, buf);
};

fn finish(mac: *mac::mac) void = {
	let hm = mac: *state;

	bytes::zero(hm.keypad);
	free(hm.keypad);
	io::close(hm.h);
};
