// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use ascii;
use bufio;
use encoding::base64;
use errors;
use io;
use os;
use strings;
use strio;

const begin: str = "-----BEGIN ";
const end: str = "-----END ";
const suffix: str = "-----";

export type decoder = struct {
	in: bufio::bufstream,
	label: strio::stream,
	buf: []u8,
};

export type b64stream = struct {
	stream: io::stream,
	in: *bufio::bufstream,
};

export type pemdecoder = struct {
	stream: io::stream,
	in: *bufio::bufstream,
	b64_in: b64stream,
	b64: base64::decoder,
	// XXX: kind of dumb but it saves us some memory management problems
	b64_ready: bool,
};

const pemdecoder_vt: io::vtable = io::vtable {
	reader = &pem_read,
	...
};

const b64stream_r_vt: io::vtable = io::vtable {
	reader = &b64_read,
	...
};

// Creates a new PEM decoder. The caller must either read it until it returns
// [[io::EOF]], or call [[finish]] to free state associated with the parser.
export fn newdecoder(in: io::handle) decoder = {
	let buf: []u8 = alloc([0...], os::BUFSIZ);
	return decoder {
		in = bufio::buffered(in, buf, []),
		buf = buf,
		label = strio::dynamic(),
	};
};

// Frees state associated with this [[decoder]].
export fn finish(dec: *decoder) void = {
	io::close(&dec.label)!;
	free(dec.buf);
};

// Converts an I/O error returned from a PEM decoder into a human-friendly
// string.
export fn strerror(err: io::error) const str = {
	match (err) {
	case errors::invalid =>
		return "Invalid PEM data";
	case =>
		return io::strerror(err);
	};
};

// Finds the next PEM boundary in the stream, ignoring any non-PEM data, and
// returns the label and a [[pemdecoder]] from which the encoded data may be
// read, or [[io::EOF]] if no further PEM boundaries are found. The user must
// completely read the pemdecoder until it returns [[io::EOF]] before calling
// [[next]] again.
//
// The label returned by this function is borrowed from the decoder state and
// does not contain "-----BEGIN " or "-----".
export fn next(dec: *decoder) ((str, pemdecoder) | io::EOF | io::error) = {
	for (true) {
		// XXX: This can be improved following
		// https://todo.sr.ht/~sircmpwn/hare/562
		const line = match (bufio::scanline(&dec.in)?) {
		case io::EOF =>
			return io::EOF;
		case let line: []u8 =>
			yield match (strings::try_fromutf8(line)) {
			case let s: str =>
				yield s;
			case =>
				return errors::invalid;
			};
		};
		defer free(line);

		if (!strings::hasprefix(line, begin)
				|| !strings::hassuffix(line, suffix)) {
			continue;
		};

		strio::reset(&dec.label);
		const label = strings::sub(line,
			len(begin), len(line) - len(suffix));
		strio::concat(&dec.label, label)!;

		return (strio::string(&dec.label), pemdecoder {
			stream = &pemdecoder_vt,
			in = &dec.in,
			b64_ready = false,
			...
		});
	};

	abort(); // Unreachable
};

fn pem_read(st: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	// We need to set up two streams. This is the stream which is actually
	// returned to the caller, which calls the base64 decoder against a
	// special stream (b64stream) which trims out whitespace and EOF's on
	// -----END.
	const st = st: *pemdecoder;
	assert(st.stream.reader == &pem_read);
	if (!st.b64_ready) {
		st.b64_in = b64stream {
			stream = &b64stream_r_vt,
			in = st.in,
		};
		st.b64 = base64::newdecoder(&base64::std_encoding, &st.b64_in);
		st.b64_ready = true;
	};

	match (io::read(&st.b64, buf)?) {
	case let z: size =>
		return z;
	case io::EOF =>
		yield;
	};

	const line = match (bufio::scanline(st.in)?) {
	case io::EOF =>
		return io::EOF;
	case let line: []u8 =>
		yield match (strings::try_fromutf8(line)) {
		case let s: str =>
			yield s;
		case =>
			return errors::invalid;
		};
	};
	defer free(line);

	if (!strings::hasprefix(line, end)
			|| !strings::hassuffix(line, suffix)) {
		return errors::invalid;
	};

	// XXX: We could verify the trailer matches but the RFC says it's
	// optional.
	return io::EOF;
};

fn b64_read(st: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	const st = st: *b64stream;
	assert(st.stream.reader == &b64_read);

	const z = match (io::read(st.in, buf)?) {
	case let z: size =>
		yield z;
	case io::EOF =>
		return errors::invalid; // Missing -----END
	};

	// Trim off whitespace and look for -----END
	let sub = buf[..z];
	for (let i = 0z; i < len(sub); i += 1) {
		if (sub[i] == '-') {
			bufio::unread(st.in, sub[i..]);
			sub = sub[..i];
			break;
		};
		if (ascii::isspace(sub[i]: u32: rune)) {
			static delete(sub[i]);
			i -= 1;
			continue;
		};
	};

	if (len(sub) == 0) {
		return io::EOF;
	};

	return len(sub);
};
