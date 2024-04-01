// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::utf8;

// Returns the index of the first occurance of 'needle' in the 'haystack', or
// void if not present. The index returned is the rune-wise index, not the
// byte-wise index.
export fn index(haystack: str, needle: (str | rune)) (size | void) = {
	match (needle) {
	case let r: rune =>
		return index_rune(haystack, r);
	case let s: str =>
		return index_string(haystack, s);
	};
};

// Returns the index of the last occurance of 'needle' in the 'haystack', or
// void if not present. The index returned is the rune-wise index, not the
// byte-wise index.
export fn rindex(haystack: str, needle: (str | rune)) (size | void) = {
	match (needle) {
	case let r: rune =>
		return rindex_rune(haystack, r);
	case let s: str =>
		return rindex_string(haystack, s);
	};
};

fn index_rune(s: str, r: rune) (size | void) = {
	let iter = iter(s);
	for (let i = 0z; true; i += 1) {
		match (next(&iter)) {
		case let n: rune =>
			if (r == n) {
				return i;
			};
		case done =>
			break;
		};
	};
};

fn rindex_rune(s: str, r: rune) (size | void) = {
	let iter = riter(s);
	for (let i = len(s) - 1; true; i -= 1) {
		match (next(&iter)) {
		case let n: rune =>
			if (r == n) {
				return i;
			};
		case done =>
			break;
		};
	};
};

fn index_string(s: str, needle: str) (size | void) = {
	let s_iter = iter(s);
	for (let i = 0z; true; i += 1) {
		let rest_iter = s_iter;
		let needle_iter = iter(needle);
		for (true) {
			const rest_rune = next(&rest_iter);
			const needle_rune = next(&needle_iter);
			if (rest_rune is done && !(needle_rune is done)) {
				break;
			};
			if (needle_rune is done) {
				return i;
			};
			if ((rest_rune as rune) != (needle_rune as rune)) {
				break;
			};
		};
		if (next(&s_iter) is done) {
			break;
		};
	};
};

fn rindex_string(s: str, needle: str) (size | void) = {
	let s_iter = riter(s);
	for (let i = len(s); true; i -= 1) {
		let rest_iter = s_iter;
		let needle_iter = riter(needle);
		for (true) {
			const rest_rune = next(&rest_iter);
			const needle_rune = next(&needle_iter);
			if (rest_rune is done && !(needle_rune is done)) {
				break;
			};
			if (needle_rune is done) {
				return i - len(needle);
			};
			if ((rest_rune as rune) != (needle_rune as rune)) {
				break;
			};
		};
		if (next(&s_iter) is done) {
			break;
		};
	};
};


@test fn index() void = {
	assert(index("hello world", 'w') as size == 6);
	assert(index("こんにちは", 'ち') as size == 3);
	assert(index("こんにちは", 'q') is void);

	assert(index("hello", "hello") as size == 0);
	assert(index("hello world!", "hello") as size == 0);
	assert(index("hello world!", "world") as size == 6);
	assert(index("hello world!", "orld!") as size == 7);
	assert(index("hello world!", "word") is void);
	assert(index("こんにちは", "ちは") as size == 3);
	assert(index("こんにちは", "きょうは") is void);

	assert(index("hello world!", "o") as size == 4);
	assert(rindex("hello world!", "o") as size == 7);
};

// Returns the byte-wise index of the first occurance of 'needle' in the
// 'haystack', or void if not present.
export fn byteindex(haystack: str, needle: (str | rune)) (size | void) = {
	return bytes::index(toutf8(haystack), match (needle) {
	case let s: str =>
		yield toutf8(s);
	case let r: rune =>
		yield if (r: u32 <= 0x7f) r: u8 else utf8::encoderune(r);
	});
};

// Returns the byte-wise index of the last occurance of 'needle' in the
// 'haystack', or void if not present.
export fn rbyteindex(haystack: str, needle: (str | rune)) (size | void) = {
	return bytes::rindex(toutf8(haystack), match (needle) {
	case let s: str =>
		yield toutf8(s);
	case let r: rune =>
		yield if (r: u32 <= 0x7f) r: u8 else utf8::encoderune(r);
	});
};

@test fn byteindex() void = {
	assert(byteindex("hello world", 'w') as size == 6);
	assert(byteindex("こんにちは", 'ち') as size == 9);
	assert(byteindex("こんにちは", 'q') is void);

	assert(byteindex("hello", "hello") as size == 0);
	assert(byteindex("hello world!", "hello") as size == 0);
	assert(byteindex("hello world!", "world") as size == 6);
	assert(byteindex("hello world!", "orld!") as size == 7);
	assert(byteindex("hello world!", "word") is void);
	assert(byteindex("こんにちは", "ちは") as size == 9);
	assert(byteindex("こんにちは", "きょうは") is void);

	assert(byteindex("またあったね", "た") as size == 3);
	assert(rbyteindex("またあったね", "た") as size == 12);
};
