// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::utf8;
use io;
use memio;
use strings;

@test fn read_byte() void = {
	let buf = memio::fixed([1, 3, 3, 7]);

	assert(read_byte(&buf) as u8 == 1);
	assert(read_byte(&buf) as u8 == 3);
	assert(read_byte(&buf) as u8 == 3);
	assert(read_byte(&buf) as u8 == 7);
	assert(read_byte(&buf) is io::EOF);
};

@test fn read_tok() void = {
	let buf = memio::fixed([1, 3, 4, 5, 3, 7]);

	let tok = read_tok(&buf, 4) as []u8;
	defer free(tok);
	assert(bytes::equal(tok, [1, 3]));

	let tok = read_tok(&buf, 7) as []u8;
	defer free(tok);
	assert(bytes::equal(tok, [5, 3]));

	assert(read_tok(&buf, 1) is io::EOF);
};

@test fn read_line() void = {
	let helloworld = strings::toutf8("hello\nworld");
	let buf = memio::fixed(helloworld);

	let line = read_line(&buf) as []u8;
	defer free(line);
	assert(bytes::equal(line, strings::toutf8("hello")));

	let line = read_line(&buf) as []u8;
	defer free(line);
	assert(bytes::equal(line, strings::toutf8("world")));

	assert(read_line(&buf) is io::EOF);
};

@test fn read_rune() void = {
	let in = memio::fixed([
		0xE3, 0x81, 0x93, 0xE3, 0x82, 0x93, 0xE3, 0x81,
		0xAB, 0xE3, 0x81, 0xA1, 0xE3, 0x81, 0xAF, 0x00,
	]);

	const expected: [_](rune | utf8::invalid | io::EOF | io::error) = [
		'こ', 'ん', 'に', 'ち', 'は', '\0', io::EOF,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		let want = expected[i];

		match (read_rune(&in)) {
		case let r: rune =>
			assert(want is rune && want as rune == r);
		case io::EOF =>
			assert(want is io::EOF);
		case =>
			abort();
		};
	};
};

@test fn scan_rune() void = {
	let in = memio::fixed(strings::toutf8("hello"));
	let scanner = newscanner(&in, 32);

	const expected: [_](rune | utf8::invalid | io::EOF | io::error) = [
		'h', 'e', 'l', 'l', 'o', io::EOF,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		let want = expected[i];

		match (scan_rune(&scanner)) {
		case let r: rune =>
			assert(want is rune && want as rune == r);
		case io::EOF =>
			assert(want is io::EOF);
		case =>
			abort();
		};
	};
};

@test fn scan_rune_cutoff() void = {
	let in = memio::fixed([
		'a', 0xE3,
	]);
	let scanner = newscanner(&in, 32);

	const expected: [_](rune | utf8::invalid | io::EOF | io::error) = [
		'a', utf8::invalid,
	];
	for (let i = 0z; i < len(expected); i += 1) {
		let want = expected[i];

		match (scan_rune(&scanner)) {
		case let r: rune =>
			assert(want is rune && want as rune == r);
		case io::EOF =>
			assert(want is io::EOF);
		case utf8::invalid =>
			assert(want is utf8::invalid);
		case =>
			abort();
		};
	};
};

@test fn scan_byte() void = {
	let in = memio::fixed([1, 2, 3]);
	let scanner = newscanner(&in, 3);

	assert(scan_byte(&scanner) as u8 == 1);
	assert(scan_byte(&scanner) as u8 == 2);
	assert(scan_byte(&scanner) as u8 == 3);
	assert(scan_byte(&scanner) is io::EOF);
};

@test fn scan_read() void = {
	const expected: [_]u8 = [
		0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b,
	];
	let in = memio::fixed(expected);

	let scanner = newscanner(&in, 2);
	defer finish(&scanner);
	let result = io::drain(&scanner)!;
	defer free(result);
	assert(bytes::equal(expected, result));
};

@test fn scan_unread() void = {
	const expected: str = " I will not repeat  \nDone!\n";
	let in = memio::fixed(strings::toutf8(expected));

	let scanner = newscanner(&in, 32);
	defer finish(&scanner);

	let b = scan_byte(&scanner) as u8;
	unread(&scanner, [b]);

	let b = scan_rune(&scanner) as rune;
	unread(&scanner, utf8::encoderune(b));

	let l = scan_line(&scanner)! as const str;
	assert(l == " I will not repeat  ");

	unread(&scanner, strings::toutf8("\n"));
	unread(&scanner, strings::toutf8(l));
	let l = scan_line(&scanner)! as const str;
	assert(l == " I will not repeat  ");

	unread(&scanner, strings::toutf8("\n"));
	unread(&scanner, strings::toutf8(strings::trim(l)));
	let l = scan_line(&scanner)! as const str;
	assert(l == "I will not repeat");

	unread(&scanner, strings::toutf8("See?\n"));
	let l = scan_line(&scanner)! as const str;
	assert(l == "See?");

	let b = scan_rune(&scanner) as rune;
	unreadrune(&scanner, b);
	unreadrune(&scanner, ' ');
	unread(&scanner, strings::toutf8("I'm"));
	let l = scan_line(&scanner)! as const str;
	assert(l == "I'm Done!");

	assert(scan_line(&scanner) is io::EOF);
};
