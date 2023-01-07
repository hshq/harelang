// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use bytes;
use encoding::utf8;
use io;
use strings;
use types;

// Reads a single byte from an [[io::handle]].
export fn scanbyte(file: io::handle) (u8 | io::EOF | io::error) = {
	let buf: [1]u8 = [0...];

	match (io::readall(file, buf)?) {
	case let read: size =>
		if (read > 0) {
			return buf[0];
		} else {
			return io::EOF;
		};
	case io::EOF =>
		return io::EOF;
	};
};

// Reads a slice of bytes until the delimiter. Delimiter is not included. The
// return value must be freed by the caller.
export fn scantok(file: io::handle, delim: u8...) ([]u8 | io::EOF | io::error) = {
	let buf: []u8 = [];

	for (true) {
		match (scanbyte(file)?) {
		case let res: u8 =>
			if (bytes::contains(delim, res)) {
				break;
			};
			append(buf, res);
		case io::EOF =>
			if (len(buf) == 0) {
				return io::EOF;
			};
			break;
		};
	};

	return buf;
};

// Reads a slice of bytes until a newline character (\n, 0x0A). Newline itself
// is not included. The return value must be freed by the caller.
export fn scanline(file: io::handle) ([]u8 | io::EOF | io::error) =
	scantok(file, '\n');

// Reads a rune from a UTF-8 stream.
export fn scanrune(
	file: io::handle,
) (rune | utf8::invalid | io::EOF | io::error) = {
	let b: [4]u8 = [0...];
	match (io::readall(file, b[..1])?) {
	case let n: size => void;
	case io::EOF =>
		return io::EOF;
	};

	const sz = match (utf8::utf8sz(b[0])) {
	case let z: size =>
		yield z;
	case void =>
		return utf8::invalid;
	};

	if (sz == 1) {
		return b[0]: u32: rune;
	};

	match (io::readall(file, b[1..sz])) {
	case let n: size => void;
	case io::EOF =>
		return io::EOF;
	case let err: io::error =>
		return if (err is io::underread) utf8::invalid else err;
	};

	let dec = utf8::decode(b[..sz]);
	match (utf8::next(&dec)?) {
	case let r: rune =>
		return r;
	case void =>
		return io::EOF;
	case utf8::more =>
		return utf8::invalid;
	};
};

@test fn scanbyte() void = {
	let buf = fixed([1, 3, 3, 7], io::mode::READ);

	assert(scanbyte(&buf) as u8 == 1);
	assert(scanbyte(&buf) as u8 == 3);
	assert(scanbyte(&buf) as u8 == 3);
	assert(scanbyte(&buf) as u8 == 7);
	assert(scanbyte(&buf) is io::EOF);
};

@test fn scantok() void = {
	let buf = fixed([1, 3, 4, 5, 3, 7], io::mode::READ);

	let tok = scantok(&buf, 4) as []u8;
	defer free(tok);
	assert(bytes::equal(tok, [1, 3]));

	let tok = scantok(&buf, 7) as []u8;
	defer free(tok);
	assert(bytes::equal(tok, [5, 3]));

	assert(scantok(&buf, 1) is io::EOF);
};

@test fn scanline() void = {
	let helloworld = strings::toutf8("hello\nworld");
	let buf = fixed(helloworld, io::mode::READ);

	let line = scanline(&buf) as []u8;
	defer free(line);
	assert(bytes::equal(line, strings::toutf8("hello")));

	let line = scanline(&buf) as []u8;
	defer free(line);
	assert(bytes::equal(line, strings::toutf8("world")));

	assert(scanline(&buf) is io::EOF);
};

@test fn scanrune() void = {
	let in = fixed([
		0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81,
		0xAB, 0xE3, 0x81, 0xA1, 0xE3, 0x81, 0xAF, 0x00,
	], io::mode::READ);

	const expected: [_](rune | utf8::invalid | io::EOF | io::error) = [
		'こ', 'ん', 'に', 'ち', 'は', '\0', io::EOF,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		let want = expected[i];

		match (scanrune(&in)) {
		case let r: rune =>
			assert(want is rune && want as rune == r);
		case io::EOF =>
			assert(want is io::EOF);
		case =>
			abort();
		};
	};
};
