use bufio;
use bytes;
use io;
use strio;
use strings;

// RFC 4648 standard "base64" base 64 encoding alphabet.
export const standard: []u8 = [
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/'
];

// RFC 4648 URL and filename safe "base64url" base 64 encoding alphabet.
export const urlsafe: []u8 = [
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '-', '_'
];

// The padding character used at the end of encoding.
export def PADDING: u8 = '=': u32: u8;

// Indicates that invalid input was found while decoding, either in the form of
// characters outside of the base 64 alphabet, insufficient padding, or trailing
// characters. Contains the index of the first invalid character.
export type invalid = !size;

// Encodes a byte slice using a base 64 encoding alphabet, with padding, and
// writes it to an [[io::stream]]. The number of bytes written is returned.
export fn encode(
	alphabet: []u8,
	sink: *io::stream,
	b: []u8
) (size | io::error) = {
	let z = 0z;
	let i = 0z;
	for (i + 2 < len(b); i += 3) {
		z += io::write(sink, [
			alphabet[b[i] >> 2],
			alphabet[(b[i] & 0x3) << 4 | b[i + 1] >> 4],
			alphabet[(b[i + 1] & 0xf) << 2 | b[i + 2] >> 6],
			alphabet[b[i + 2] & 0x3F],
		])?;
	};
	if (len(b) - i > 0) {
		if (len(b) - i == 2) {
			z += io::write(sink, [
				alphabet[b[i] >> 2],
				alphabet[(b[i] & 0x3) << 4 | b[i + 1] >> 4],
				alphabet[(b[i + 1] & 0xf) << 2],
				PADDING,
			])?;
		} else {
			z += io::write(sink, [
				alphabet[b[i] >> 2],
				alphabet[(b[i] & 0x3) << 4],
				PADDING,
				PADDING,
			])?;
		};
	};
	return z;
};

// Calls [[encode]] with the [[standard]] base 64 encoding alphabet.
export fn stdencode(
	sink: *io::stream,
	b: []u8,
) (size | io::error) = encode(standard, sink, b);

// Calls [[encode]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urlencode(
	sink: *io::stream,
	b: []u8,
) (size | io::error) = encode(urlsafe, sink, b);

// Encodes a byte slice using a base 64 encoding alphabet, with padding, and
// returns it. The caller must free the return value.
export fn encodestr(alphabet: []u8, b: []u8) str = {
	let sink = strio::dynamic();
	encode(alphabet, sink, b) as size;
	return strio::finish(sink);
};

// Calls [[encodestr]] with the [[standard]] base 64 encoding alphabet.
export fn stdencodestr(b: []u8) str = encodestr(standard, b);

// Calls [[encodestr]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urlencodestr(b: []u8) str = encodestr(urlsafe, b);

@test fn encode() void = {
	const in: [_]u8 = ['f', 'o', 'o', 'b', 'a', 'r'];
	const expect: [_]str = [
		"",
		"Zg==",
		"Zm8=",
		"Zm9v",
		"Zm9vYg==",
		"Zm9vYmE=",
		"Zm9vYmFy"
	];
	for (let i = 0z; i < len(in); i += 1) {
		let s = encodestr(standard, in[..i]);
		defer free(s);
		assert(s == expect[i]);
	};
};

// Decodes base 64-encoded data in the given base 64 alphabet, with padding,
// from an [[io::stream]]. The number of bytes written is returned.
export fn decode(
	alphabet: []u8,
	in: *io::stream,
	out: *io::stream,
) (size | invalid | io::error) = {
	const INVALID_OR_PAD = 255u8;
	let decoder: [256]u8 = [INVALID_OR_PAD...];
	for (let i = 0z; i < len(alphabet); i += 1) {
		decoder[alphabet[i]] = i: u8;
	};

	let count = 0z;
	let z = 0z;
	for (true) {
		let buf: [4]u8 = [0...];
		match (io::read(in, buf)) {
			size => {
				for (let i = 0z; i < 2; i += 1) {
					if (decoder[buf[i]] == INVALID_OR_PAD) {
						return (count + i): invalid;
					} else {
						buf[i] = decoder[buf[i]];
					};
				};

				if (decoder[buf[2]] == INVALID_OR_PAD) {
					if (buf[2] != PADDING) {
						return (count + 2z): invalid;
					};
					if (buf[3] != PADDING) {
						return (count + 3z): invalid;
					};
					z += io::write(out, [
						buf[0] << 2 | buf[1] >> 4,
					])?;
					let extra: []u8 = [0];
					return match (io::read(in, extra)) {
						size => (count + 4z): invalid,
						io::EOF => z,
					};
				} else {
					buf[2] = decoder[buf[2]];
				};

				if (decoder[buf[3]] == INVALID_OR_PAD) {
					if (buf[3] != PADDING) {
						return (count + 3z): invalid;
					};
					z += io::write(out, [
						buf[0] << 2 | buf[1] >> 4,
						buf[1] << 4 | buf[2] >> 2,
					])?;
					let extra: []u8 = [0];
					return match (io::read(in, extra)) {
						size => (count + 4z): invalid,
						io::EOF => z,
					};
				} else {
					buf[3] = decoder[buf[3]];
				};

				z += io::write(out, [
					buf[0] << 2 | buf[1] >> 4,
					buf[1] << 4 | buf[2] >> 2,
					buf[2] << 6 | buf[3],
				])?;
				count += 4;
			},
			io::EOF => {
				break;
			},
		};
	};
	return z;
};

// Calls [[decode]] with the [[standard]] base 64 encoding alphabet.
export fn stddecode(
	in: *io::stream,
	out: *io::stream,
) (size | invalid | io::error) = decode(standard, in, out);

// Calls [[decode]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecode(
	in: *io::stream,
	out: *io::stream,
) (size | invalid | io::error) = decode(urlsafe, in, out);

// Decodes base 64-encoded data in the given base 64 alphabet, with padding,
// from an [[io::stream]]. Every four input bytes are guaranteed to either be
// decoded into the user-provided buffer or return [[invalid]]. The number of
// bytes written is returned.
export fn decode_static(
	alphabet: []u8,
	out: []u8,
	in: *io::stream,
) (size | invalid) = {
	let buf = bufio::fixed(out, io::mode::WRITE);
	defer io::close(buf);
	return match (decode(alphabet, in, buf)) {
		io::error => abort(),
		z: invalid => z: invalid,
		z: size => z,
	};
};

// Calls [[decode_static]] with the [[standard]] base 64 encoding alphabet.
export fn stddecode_static(out: []u8, in: *io::stream) (size | invalid) = {
	return decode_static(standard, out, in);
};

// Calls [[decode_static]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecode_static(out: []u8, in: *io::stream) (size | invalid) = {
	return decode_static(urlsafe, out, in);
};

// Decodes a string of base 64-encoded data in the given base 64 encoding
// alphabet, with padding, into a byte slice. The caller must free the return
// value.
export fn decodestr(alphabet: []u8, in: str) ([]u8 | invalid) = {
	return decodeslice(alphabet, strings::toutf8(in));
};

// Calls [[decodestr]] with the [[standard]] base 64 encoding alphabet.
export fn stddecodestr(in: str) ([]u8 | invalid) = decodestr(standard, in);

// Calls [[decodestr]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecodestr(in: str) ([]u8 | invalid) = decodestr(urlsafe, in);

// Decodes a string of base 64-encoded data in the given base 64 encoding
// alphabet, with padding. Every four input bytes are guaranteed to either be
// decoded into the user-provided buffer or return [[invalid]]. The number of
// bytes written is returned.
export fn decodestr_static(
	alphabet: []u8,
	out: []u8,
	in: str,
) (size | invalid) = {
	return decodeslice_static(alphabet, out, strings::toutf8(in));
};

// Calls [[decodestr_static]] with the [[standard]] base 64 encoding alphabet.
export fn stddecodestr_static(out: []u8, in: str) (size | invalid) = {
	return decodestr_static(standard, out, in);
};

// Calls [[decodestr_static]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecodestr_static(out: []u8, in: str) (size | invalid) = {
	return decodestr_static(urlsafe, out, in);
};

// Decodes a byte slice of base 64-encoded data in the given base 64 encoding
// alphabet, with padding, into a byte slice. The caller must free the return
// value.
export fn decodeslice(alphabet: []u8, in: []u8) ([]u8 | invalid) = {
	let out = bufio::dynamic(io::mode::WRITE);
	let in = bufio::fixed(in, io::mode::READ);
	defer io::close(in);
	return match (decode(alphabet, in, out)) {
		io::error => abort(),
		z: invalid => z: invalid,
		size => bufio::finish(out),
	};
};

// Calls [[decodeslice]] with the [[standard]] base 64 encoding alphabet.
export fn stddecodeslice(in: []u8) ([]u8 | invalid) = decodeslice(standard, in);

// Calls [[decodeslice]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecodeslice(in: []u8) ([]u8 | invalid) = decodeslice(urlsafe, in);

// Decodes a byte slice of base 64-encoded data in the given base 64 encoding
// alphabet, with padding. Every four input bytes are guaranteed to either be
// decoded into the user-provided buffer or return [[invalid]]. The number of
// bytes written is returned.
export fn decodeslice_static(
	alphabet: []u8,
	out: []u8,
	in: []u8,
) (size | invalid) = {
	let in = bufio::fixed(in, io::mode::READ);
	defer io::close(in); // bufio::finish?
	return decode_static(alphabet, out, in);
};

// Calls [[decodeslice_static]] with the [[standard]] base 64 encoding alphabet.
export fn stddecodeslice_static(out: []u8, in: []u8) (size | invalid) = {
	return decodeslice_static(standard, out, in);
};

// Calls [[decodeslice_static]] with the [[urlsafe]] base 64 encoding alphabet.
export fn urldecodeslice_static(out: []u8, in: []u8) (size | invalid) = {
	return decodeslice_static(urlsafe, out, in);
};

@test fn decode() void = {
	const in: [_]str = [
		"",
		"Zg==",
		"Zm8=",
		"Zm9v",
		"Zm9vYg==",
		"Zm9vYmE=",
		"Zm9vYmFy",
	];
	const expect: [_]u8 = ['f', 'o', 'o', 'b', 'a', 'r'];
	for (let i = 0z; i < len(in); i += 1) {
		let s = stddecodestr(in[i]) as []u8;
		defer free(s);
		assert(bytes::equal(s, expect[..i]));
	};
	
	const bad: [_]str = [
		"A",
		"AA",
		"AAA",
		"!!!!",
		"====",
		"A=A=",
		"AA=A",
		"Zg==Zg==",
	];
	const badindex: [_]size = [1, 2, 3, 0, 0, 1, 3, 4];
	for (let i = 0z; i < len(bad); i += 1) {
		assert(stddecodestr(bad[i]) as invalid == badindex[i]: invalid);
	};
};
