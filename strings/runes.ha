// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

// Returns a slice of runes for a string in O(n). The caller must free the
// return value.
export fn torunes(s: str) []rune = {
	let sl: []rune = [];
	let iter = iter(s);
	for (let r => next(&iter)) {
		append(sl, r);
	};
	return sl;
};

// Returns a string from a slice of runes. The caller must free the return value.
export fn fromrunes(runes: []rune) str = {
	let bytes: []u8 = [];
	for (let r .. runes) {
		const bs = utf8::encoderune(r);
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

	for (let (string, runes) .. tests) {
		const s = fromrunes(runes);
		defer free(s);
		assert(s == string);

		const rs = torunes(s);
		defer free(rs);
		assert(len(rs) == len(runes));

		for (let j = 0z; j < len(rs); j += 1) {
			assert(rs[j] == runes[j]);
		};
	};
};
