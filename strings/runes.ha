// License: MPL-2.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
use encoding::utf8;

// Returns a slice of runes for a string in O(n). The caller must free the
// return value.
export fn runes(s: str) []rune = {
	let sl: []rune = alloc([], len(s));
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
	return fromutf8(bytes)!;
};

@test fn fromrunes() void = {
	const rs = ['H', 'a', 'r', 'r', 'i', 'e', 't'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "Harriet", "strings::fromrunes() error (Harriet)");

	const rs: []rune = [];
	const s = fromrunes(rs); defer free(s);
	assert(s == "", "strings::fromrunes() error (empty)");

	const rs = ['.'];
	const s = fromrunes(rs); defer free(s);
	assert(s == ".", "strings::fromrunes() error (period)");

	const rs = ['\a', '\b', '\f', '\n', '\r', '\t', '\v'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "\a\b\f\n\r\t\v", "strings::fromrunes() error (control chars)");

	const rs = ['H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd', '!'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "Hello, world!", "strings::fromrunes() error (English)");

	const rs = ['¡', 'H', 'o', 'l', 'a', ' ', 'M', 'u', 'n', 'd', 'o', '!'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "¡Hola Mundo!", "strings::fromrunes() error (Spanish)");

	const rs = ['Γ', 'ε', 'ι', 'ά', ' ', 'σ', 'ο', 'υ', ' ', 'Κ', 'ό', 'σ', 'μ', 'ε', '!'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "Γειά σου Κόσμε!", "strings::fromrunes() error (Greek)");

	const rs = ['П', 'р', 'и', 'в', 'е', 'т', ',', ' ', 'м', 'и', 'р', '!'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "Привет, мир!", "strings::fromrunes() error (Russian)");

	const rs = ['こ', 'ん', 'に', 'ち', 'は', '世', '界', '！'];
	const s = fromrunes(rs); defer free(s);
	assert(s == "こんにちは世界！", "strings::fromrunes() error (Japanese)");
};
