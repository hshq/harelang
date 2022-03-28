// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Vlad-Stefan Harbuz <vlad@vladh.net>
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

fn index_rune(s: str, r: rune) (size | void) = {
	let iter = iter(s);
	for (let i = 0z; true; i += 1) {
		match (next(&iter)) {
		case let n: rune =>
			if (r == n) {
				return i;
			};
		case void =>
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
			if (rest_rune is void && !(needle_rune is void)) {
				break;
			};
			if (needle_rune is void) {
				return i;
			};
			if ((rest_rune as rune) != (needle_rune as rune)) {
				break;
			};
		};
		if (next(&s_iter) is void) {
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
};

// Returns the byte-wise index of the first occurance of 'needle' in the
// 'haystack', or void if not present.
export fn byteindex(haystack: str, needle: (str | rune)) (size | void) = {
	return bytes::index(toutf8(haystack), match (needle) {
	case let s: str =>
		yield toutf8(s);
	case let r: rune =>
		yield if (r: u32 <= 0x7f) r: u32: u8 else utf8::encoderune(r);
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
};
