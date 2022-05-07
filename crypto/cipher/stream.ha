// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use io;
use crypto::math::{xor};

// An abstract interface for implementing cipher streams
export type stream = struct {
	xor: *fn(s: *stream, dest: []u8, src: []u8) void,
	finish: *fn(s: *stream) void,
};

// Applies xor of the key produced by the stream to src and writes the result
// in dest. 'dest' and 'src' may be the same slice, and both slices must have
// the same length.
export fn stream_xor(s: *stream, dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src), "stream_xor: slices must have the same length");
	s.xor(s, dest, src);
};


// An abstract interface for implementing streams that encrypt or decrypt by
// producing a key stream that is xored with the data. The implementing stream
// must call [[xorstream_init]] after creation so that [[io::reader]], 
// [[io::writer]] and [[io::closer]] functions will be registered.
//
// After initializing the xorstream can be written to with [[io::write]] to
// encrypt data and write it to the handle 'h'. For decrpytion 'h' will provide
// the ciphertext and the plaintext can be read from the xorstream with 
// [[io::read]].
export type xorstream = struct {
	stream: io::stream,
	h: io::handle,

	// Returns usable part of the current key buffer. The buffer must be
	// modifiable by the callee.
	keybuf: *fn(s: *xorstream) []u8,

	// Advances the start index of the keybuffer by 'n' bytes.
	advance: *fn(s: *xorstream, n: size) void,

	// Erases all sensitive data from memory.
	finish: *fn(s: *xorstream) void,
};

// Initialises a xorstream with the handle 'h' and sets [[io::reader]], 
// [[io::writer]] and [[io::closer]] functions.
export fn xorstream_init(xs: *xorstream, h: io::handle) void = {
	xs.h = h;
	xs.stream = &xorstream_vtable;
};

const xorstream_vtable: io::vtable = io::vtable {
	writer = &xor_writer,
	reader = &xor_reader,
	closer = &xor_closer,
	...
};

fn xor_writer(s: *io::stream, in: const []u8) (size | io::error) = {
	let s = s: *xorstream;

	let keybuf = s.keybuf(s);

	const max = if (len(in) > len(keybuf)) {
		yield len(keybuf);
	} else {
		yield len(in);
	};
	if (max == 0) {
		return 0z;
	};

	keybuf = keybuf[..max];

	// Modify the keybuf to store the cipher for writing, so that we won't
	// need additional space.
	xor(keybuf, keybuf, in[..max]);

	match (io::write(s.h, keybuf)) {
	case let n: size =>
		if (n < max) {
			// revert the unused part of the keybuf to allow retry
			xor(keybuf[n..], keybuf[n..], in[n..max]);
		};
		s.advance(s, n);
		return n;
	case let e: io::error =>
		// revert the keybuf to allow retry
		xor(keybuf, keybuf, in[..max]);
		return e;
	};
};

fn xor_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	let s = s: *xorstream;

	if (len(buf) == 0) {
		return 0z;
	};

	match (io::read(s.h, buf)) {
	case io::EOF =>
		return io::EOF;
	case let e: io::error =>
		return e;
	case let n: size =>
		for (let z = 0z; z < n) {
			let keybuf = s.keybuf(s);

			const max = if (n - z > len(keybuf)) {
				yield len(keybuf);
			} else {
				yield n - z;
			};

			xor(buf[..max], buf[..max], keybuf[..max]);
			buf = buf[max..];
			s.advance(s, max);
			z += max;
		};
		return n;
	};
};

fn xor_closer(s: *io::stream) (void | io::error) = {
	let s = s: *xorstream;
	s.finish(s);
};

