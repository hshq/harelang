use crypto::math;

export type ctr_stream = struct {
	stream,
	b: *block,
	counter: []u8,
	xorbuf: []u8,
	xorused: size,
};

// Creates a ctr [[stream]] on top of given block cipher. The caller must 
// provide the initiation vector and a buffer for the state. The size of
// the buffer depends on the block cipher. Use [[crypto::aes::CTR_BUFSIZE]]
// for the stdlib AES implementation.
export fn ctr(b: *block, iv: []u8, buf: []u8) ctr_stream = {
	assert(len(iv) == sz(b), "iv is of invalid block size");
	assert(len(buf) >= sz(b) * 2, "buf must be at least 2 * blocksize");

	let bsz = sz(b);

	// one buf block is used for the counter
	let counter = buf[0..bsz];

	// the remaining space is used to store the key stream. It needs
	// to be at least the size of one block and ideally the size of
	// nparallel(b) times the block size. A bigger buffer than the latter
	// option is of no use.
	let xorbuf = buf[bsz..];

	counter[..] = iv[..];

	// cap the buffer to a multiple of bsz.
	let maxxorbufsz = sz(b) * nparallel(b);
	let xorbufsz = len(xorbuf);
	if (xorbufsz < maxxorbufsz) {
		xorbufsz = xorbufsz - xorbufsz % sz(b);
	} else {
		xorbufsz = maxxorbufsz;
	};

	return ctr_stream {
		xor = &ctr_stream_xor,
		b = b,
		counter = counter,
		xorbuf = xorbuf,
		// mark all as used to force fill xorbuf
		xorused = xorbufsz,
	};
};

fn ctr_stream_xor(s: *stream, dest: []u8, src: []u8) void = {
	let ctr = s: *ctr_stream;
	let bsz = sz(ctr.b);
	let nparallel = nparallel(ctr.b);
	let i = 0z;

	for (true) {
		for (ctr.xorused < len(ctr.xorbuf)) {
			dest[i] = src[i] ^ ctr.xorbuf[ctr.xorused];
			ctr.xorused += 1;
			i += 1;
			if (i >= len(dest)) {
				return;
			};
		};
		fill_xorbuf(ctr);
	};
};

fn fill_xorbuf(ctr: *ctr_stream) void = {
	let bsz = sz(ctr.b);
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
