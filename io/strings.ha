use encoding::utf8;
use types;

// TODO: Do we want some kind of io::text_stream?

// Reads a rune from a UTF-8 stream.
export fn getrune(in: *io::stream) (rune | utf8::invalid | EOF | error) = {
	let b: [4]u8 = [0...];
	match (read(in, b[..1])) {
		e: (error | EOF) => return e,
		n: size => assert(n == 1),
	};

	const sz = utf8::utf8sz(b[0]);
	if (sz == types::SIZE_MAX) {
		return utf8::invalid;
	};

	if (sz == 1) {
		return b[0]: u32: rune;
	};

	match (read(in, b[1..sz])) {
		e: (error | EOF) => return e,
		n: size => assert(n == sz - 1),
	};

	let dec = utf8::decode(b[..sz]);
	return match (utf8::next(&dec)) {
		r: rune => r,
		utf8::invalid => utf8::invalid,
		(void | utf8::more) => EOF,
	};
};
