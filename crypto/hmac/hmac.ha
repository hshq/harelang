use crypto::math;
use hash;
use io;

export type state = struct {
	hash::hash,
	hinner: *hash::hash,
	houter: *hash::hash,
	okeypad: []u8,
	ikeypad: []u8,
	sumbuf: []u8,
};

// Creates a [[hash::hash]] that computes an HMAC using the provided hash
// creation function, e.g. [[crypto::sha256::create]].
export fn hmac(create: *hash::createfunc, key: []u8) state = {
	let hinner = create(), houter = create();
	let bsz = hash::bsz(hinner);
	let ikeypad: []u8 = bytes_alloc(bsz, 0);

	// use ikeypad to store the prepared key temporarly to avoid an
	// additional allocation.
	if (len(key) > bsz) {
		hash::write(hinner, key);
		hash::sum(hinner, ikeypad);
		hash::reset(hinner);
	} else {
		ikeypad[..len(key)] = key[..];
	};

	let okeypad: []u8 = alloc([], bsz);
	for (let i = 0z; i < bsz; i += 1) {
		append(okeypad, 0x5c ^ ikeypad[i]);
	};

	for (let i = 0z; i < bsz; i += 1) {
		ikeypad[i] = 0x36 ^ ikeypad[i];
	};

	hash::write(hinner, ikeypad);

	return state {
		writer = &write,
		reset = &reset,
		sum = &sum,
		closer = &close,
		sz = hash::sz(hinner),
		bsz = bsz,
		hinner = hinner,
		houter = houter,
		okeypad = okeypad,
		ikeypad = ikeypad,
		sumbuf = bytes_alloc(hash::sz(hinner), 0),
		...
	};
};

fn close(s: *io::stream) void = {
	let h: *state = s: *state;
	free(h.okeypad);
	free(h.ikeypad);
	free(h.sumbuf);
	io::close(h.hinner);
	io::close(h.houter);
	free(h.hinner);
	free(h.houter);
};

// TODO: https://todo.sr.ht/~sircmpwn/hare/285
fn bytes_alloc(s: size, v: u8) []u8 = {
	let b: []u8 = alloc([], s);
	for (let i = 0z; i < s; i += 1) {
		append(b, 0);
	};
	return b;
};

fn write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let h = st: *state;
	return hash::write(h.hinner, buf);
};

fn sum(hash: *hash::hash, buf: []u8) void = {
	let h = hash: *state;

	hash::sum(h.hinner, h.sumbuf[0..h.hinner.sz]);

	hash::reset(h.houter);
	hash::write(h.houter, h.okeypad);
	hash::write(h.houter, h.sumbuf[0..h.hinner.sz]);
	hash::sum(h.houter, buf);
};

fn reset(hash: *hash::hash) void = {
	let h = hash: *state;
	hash::reset(h.hinner);
	hash::write(h.hinner, h.ikeypad);
};
