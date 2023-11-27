// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

// Returns a slice of runes for a string in O(n). The caller must free the
// return value.
export fn torunes(s: str) []rune = {
	let sl: []rune = [];
	let iter = iter(s);
	for (true) {
		match (next(&iter)) {
		case void => break;
		case let r: rune =>
			append(sl, r);
		};
	};
	return sl;
};

// Returns a string from a slice of runes. The caller must free the return value.
export fn fromrunes(rs: []rune) str = {
	let bytes: []u8 = [];
	for (let i = 0z; i < len(rs); i += 1) {
		const bs = utf8::encoderune(rs[i]);
		append(bytes, bs...);
	};
	return fromutf8_unsafe(bytes);
};

@test fn fromrunes() void = {
	const tests: [_](str, []rune) = [
		("Harriet", ['H', 'a', 'r', 'r', 'i', 'e', 't']),
		("", []),
		(".", ['.']),
		("\a\b\f\n\r\t\v", ['\a', '\b', '\f', '\n', '\r', '\t', '\v']),
		("Hello, world!", ['H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd', '!']),
		("¡Hola Mundo!", ['¡', 'H', 'o', 'l', 'a', ' ', 'M', 'u', 'n', 'd', 'o', '!']),
		("Γειά σου Κόσμε!", ['Γ', 'ε', 'ι', 'ά', ' ', 'σ', 'ο', 'υ', ' ', 'Κ', 'ό', 'σ', 'μ', 'ε', '!']),
		("Привет, мир!", ['П', 'р', 'и', 'в', 'е', 'т', ',', ' ', 'м', 'и', 'р', '!']),
		("こんにちは世界！", ['こ', 'ん', 'に', 'ち', 'は', '世', '界', '！']),
	];

	for (let i = 0z; i < len(tests); i += 1) {
		const s = fromrunes(tests[i].1);
		defer free(s);
		assert(s == tests[i].0);
		const rs = torunes(s);
		defer free(rs);
		assert(len(rs) == len(tests[i].1));
		for (let j = 0z; j < len(rs); j += 1) {
			assert(rs[j] == tests[i].1[j]);
		};
	};
};
