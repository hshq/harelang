use encoding::utf8;
use rt;

type bufstream = struct {
	stream: stream,
	buf: []u8,
};

@test fn getrune() void = {
	let bs = bufstream {
		stream = stream {
			name = "buffer",
			reader = &bs_read,
			...
		},
		buf = [
			0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81,
			0xAB, 0xE3, 0x81, 0xA1, 0xE3, 0x81, 0xAF, 0x00,
		],
	};
	let in = &bs.stream;
	const expected: [_](rune | utf8::invalid | EOF | error) = [
		'こ', 'ん', 'に', 'ち', 'は', '\0', EOF,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		let want = expected[i];
		match (getrune(in)) {
			r: rune => assert(want is rune && want as rune == r),
			EOF => assert(want is EOF),
			* => abort(),
		};
	};
};

fn bs_read(s: *stream, buf: []u8) (size | error | EOF) = {
	let stream = s: *bufstream;
	if (len(stream.buf) == 0) {
		return EOF;
	};
	const n = if (len(buf) > len(stream.buf)) len(stream.buf) else len(buf);
	// TODO: Fix me up once slice copying is in
	rt::memcpy(buf: *[*]u8, stream.buf: *[*]u8, n);
	stream.buf = stream.buf[n..];
	return n;
};
