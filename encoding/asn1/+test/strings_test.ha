// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use errors;
use fmt;
use io;
use strings;


fn c_checkrange(chars: []u8, f: *fn (c: u8) bool) void = {
	for (let i = 0z; i < 256; i += 1) {
		let expected = false;
		for (let j = 0z; j < len(chars); j += 1) {
			if (chars[j] == i: u8) {
				expected = true;
				break;
			};
		};

		if (f(i: u8) != expected) {
			fmt::println(i, expected, f(i: u8))!;
		};
		assert(f(i: u8) == expected);
	};
};

@test fn c_is_num() void = {
	const chars: [_]u8 = [
		'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ',
	];
	c_checkrange(chars, &c_is_num);
};

@test fn c_is_print() void = {
	const chars: [_]u8 = [
		'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
		'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
		'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
		'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
		'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '\'',
		'(', ')', '+', ',', '-', '.', '/', ':', '=', '?',
	];
	c_checkrange(chars, &c_is_print);
};

@test fn utf8() void = {
	let buf: [16]u8 = [0...];
	let b: [_]u8 = [
		0x55,
		0x56,
		0xd0, 0x98,
		0xe0, 0xa4, 0xb9,
		0xf0, 0x90, 0x8d, 0x88
	];
	const runesat: [_]size = [0, 1, 2, 2, 4, 4, 4, 7, 7, 7, 7, 8];

	let expected: str = strings::fromutf8([0xf0, 0x90, 0x8d, 0x88])!;
	assert(read_utf8str(&d([0x0c, 0x04, 0xf0, 0x90, 0x8d, 0x88]), buf)!
		== expected);
	assert(read_utf8str(&d([0x0c, 0x03, 0xf0, 0x90, 0x8d]), buf) is invalid);

	bytes::zero(buf);
	let r = strreader(&d([0x0c, 0x04, 0xf0, 0x90, 0x8d, 0x88]), utag::UTF8_STRING)!;
	assert(io::read(&r, buf)! == 4);
	assert(bytes::equal(buf[..4], strings::toutf8(expected)));

	bytes::zero(buf);
	let expected: str = strings::fromutf8([0x55, 0x56, 0xf0, 0x90, 0x8d, 0x88])!;
	assert(read_utf8str(&d([0x0c, 0x06, 0x55, 0x56, 0xf0, 0x90, 0x8d, 0x88]), buf)!
		== expected);
	assert(read_utf8str(&d([0x0c, 0x05, 0x55, 0x56, 0xf0, 0x90, 0x8d]), buf) is invalid);

	bytes::zero(buf);
	let r = strreader(&d([0x0c, 0x06, 0x55, 0x56, 0xf0, 0x90, 0x8d, 0x88]), utag::UTF8_STRING)!;
	assert(io::read(&r, buf)! == 6);
	assert(bytes::equal(buf[..6], strings::toutf8(expected)));

	let r = strreader(&d([0x0c, 0x05, 0x55, 0x56, 0xf0, 0x90, 0x8d]), utag::UTF8_STRING)!;
	assert(unwrap_err(io::readall(&r, buf[2..]) as io::error) is invalid);

	bytes::zero(buf);
	let r = strreader(&d([0x0c, 0x06, 0x55, 0x56, 0xf0, 0x90, 0x8d, 0x88]), utag::UTF8_STRING)!;
	assert(io::read(&r, buf[..4])! == 2);
	assert(io::read(&r, buf[2..])! == 4);
	assert(bytes::equal(buf[..6], strings::toutf8(expected)));

	bytes::zero(buf);
	let r = strreader(&d([0x0c, 0x05, 0x55, 0x56, 0xf0, 0x90, 0x8d]), utag::UTF8_STRING)!;
	assert(io::read(&r, buf[..4])! == 2);
	assert(unwrap_err(io::readall(&r, buf[2..]) as io::error) is invalid);
};

@test fn t61() void = {
	let input: [_]u8 = [
		0x14, 0x29,
		0x42, 0xc8, 0x61, 0x72, 0x65, 0x6e, 0x20, 0x76, 0x65, 0x72,
		0x7a, 0x65, 0x68, 0x72, 0x65, 0x6e, 0x20, 0x67, 0x65, 0x72,
		0x6e, 0x65, 0x20, 0xc8, 0x75, 0x62, 0x65, 0x72, 0x6d, 0xc8,
		0x61, 0xfb, 0x69, 0x67, 0x20, 0x48, 0x6f, 0x6e, 0x69, 0x67,
		0x0a,
	];

	const expected: [_]u8 = [
		0x42, 0xc3, 0xa4, 0x72, 0x65, 0x6e, 0x20, 0x76, 0x65, 0x72,
		0x7a, 0x65, 0x68, 0x72, 0x65, 0x6e, 0x20, 0x67, 0x65, 0x72,
		0x6e, 0x65, 0x20, 0xc3, 0xbc, 0x62, 0x65, 0x72, 0x6d, 0xc3,
		0xa4, 0xc3, 0x9f, 0x69, 0x67, 0x20, 0x48, 0x6f, 0x6e, 0x69,
		0x67, 0x0a,
	];

	let dec = d(input);
	let r = strreader(&dec, utag::TELETEX_STRING)!;
	let result = io::drain(&r)!;
	defer free(result);
	assert(bytes::equal(expected, result));
	assert(trypeek(&dec) is io::EOF);

	// cut off multibyte char
	input[1] = 0x2;
	let r = strreader(&d(input[..4]), utag::TELETEX_STRING)!;
	assert(unwrap_err(io::drain(&r) as io::error) is invalid);

	// not enough space for multibyte char
	let buf: [24]u8 = [0...];
	let in = input[..27];
	in[1] = (len(in) - 2): u8;
	let dec = d(in);
	let r = strreader(&dec, utag::TELETEX_STRING)!;
	assert(io::read(&r, buf)! == 23);
	assert(trypeek(&dec) is badformat);

	let r = strreader(&d([
		0x14, 0x0f, 0x63, 0x6c, 0xc2, 0x65, 0x73, 0x20, 0x70, 0x75,
		0x62, 0x6c, 0x69, 0x71, 0x75, 0x65, 0x73,
	]), utag::TELETEX_STRING)!;
	let b = io::drain(&r)!;
	defer free(b);

	assert(strings::fromutf8(b)! == "cl\u00e9s publiques");
};

@test fn bmp() void = {
	let input: [_]u8 = [
		0x1e, 0x26,
		0x00, 0x48, 0x00, 0xe4, 0x00, 0x72, 0x00, 0x65, 0x00, 0x6c,
		0x00, 0x61, 0x00, 0x6e, 0x00, 0x67, 0x00, 0x20, 0x00, 0x69,
		0x01, 0x61, 0x00, 0x20, 0x00, 0x6e, 0x00, 0x65, 0x00, 0x61,
		0x00, 0x74, 0x00, 0x6f, 0x00, 0x20, 0x27, 0x64,
	];

	const expected: [_]u8 = [
		0x48, 0xc3, 0xa4, 0x72, 0x65, 0x6c, 0x61, 0x6e, 0x67, 0x20,
		0x69, 0xc5, 0xa1, 0x20, 0x6e, 0x65, 0x61, 0x74, 0x6f, 0x20,
		0xe2, 0x9d, 0xa4,
	];

	let dec = d(input);
	let r = strreader(&dec, utag::BMP_STRING)!;
	let result = io::drain(&r)!;
	defer free(result);
	assert(bytes::equal(expected, result));
	assert(trypeek(&dec) is io::EOF);
};
