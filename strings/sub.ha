// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

export type end = void;

fn utf8_byte_len_bounded(iter: *iterator, end: size) size = {
	for (let i = 0z; i < end; i += 1) {
		match (next(iter)) {
		case let r: rune =>
			continue;
		case done =>
			abort("index exceeds string length");
		};
	};
	return iter.dec.offs;
};

// Returns a substring in the range [start, end - 1], where each argument is the
// index of the Nth rune. If the end argument is given as [[end]], the end of
// the substring is the end of the original string. The lifetime of the
// substring is the same as that of the original string.
//
// Note that substringing runewise is not always the correct thing to do, and it
// may cause unexpected linguistic errors to arise. You may want to use a
// third-party Unicode module instead.
export fn sub(s: str, start: size, end: (size | end)) str = {
	let iter = iter(s);
	let starti = utf8_byte_len_bounded(&iter, start);
	let endi = match (end) {
	case let sz: size =>
		assert(start <= sz, "start is higher than end");
		yield utf8_byte_len_bounded(&iter, sz - start);
	case =>
		yield len(s);
	};
	let bytes = toutf8(s);
	return fromutf8_unsafe(bytes[starti..endi]);
};

@test fn sub() void = {
	assert(sub("a string", 2, end) == "string");
	assert(sub("a string", 0, 1) == "a");
	assert(sub("a string", 0, 3) == "a s");
	assert(sub("a string", 2, 8) == "string");
	assert(sub("a string", 4, 4) == "");
};
