// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::utf8;

// Returns true if 'in' has the given prefix.
export fn hasprefix(in: str, prefix: (str | rune)) bool = {
	let prefix = match (prefix) {
	case let r: rune =>
		yield utf8::encoderune(r);
	case let s: str =>
		yield toutf8(s);
	};
	return bytes::hasprefix(toutf8(in), prefix);
};

@test fn hasprefix() void = {
	assert(hasprefix("hello world", "hello"));
	assert(hasprefix("hello world", 'h'));
	assert(!hasprefix("hello world", "world"));
	assert(!hasprefix("hello world", 'q'));
};

// Returns true if 'in' has the given suffix.
export fn hassuffix(in: str, suff: (str | rune)) bool = {
	let suff = match (suff) {
	case let r: rune =>
		yield utf8::encoderune(r);
	case let s: str =>
		yield toutf8(s);
	};
	return bytes::hassuffix(toutf8(in), suff);
};

@test fn hassuffix() void = {
	assert(hassuffix("hello world", "world"));
	assert(hassuffix("hello world", 'd'));
	assert(!hassuffix("hello world", "hello"));
	assert(!hassuffix("hello world", 'h'));
};
