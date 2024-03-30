// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;

export type iterator = struct {
	dec:  utf8::decoder,
	reverse: bool,
};

// Initializes a string iterator, starting at the beginning of the string. You
// may copy the iterator to save its state.
//
//	let iter = strings::iter("hi!");
//	strings::next(&iter);	// 'h'
//	strings::next(&iter);	// 'i'
//
//	// Copying the iterator copies its state:
//	let dup = iter;
//	strings::next(&iter);	// '!'
//	strings::next(&iter);	// void
//	strings::next(&dup);	// '!'
//	strings::next(&dup);	// void
export fn iter(src: str) iterator = iterator {
	dec = utf8::decode(toutf8(src)),
	reverse = false,
};

// Initializes a string iterator, starting at the end of the string and moving
// backwards with each call to [[next]].
export fn riter(src: str) iterator = {
	let ret = iterator {
		dec = utf8::decode(toutf8(src)),
		reverse = true,
	};
	ret.dec.offs = len(src);
	return ret;
};

// Get the next rune from an iterator, or done if there are none left.
//
// Be aware that a rune is not the minimum lexographical unit of language in
// Unicode strings. If you use these runes to construct a new string,
// reordering, editing, or omitting any of the runes without careful discretion
// may cause linguistic errors to arise. To avoid this, you may need to use a
// third-party Unicode module instead.
export fn next(iter: *iterator) (rune | done) = move(!iter.reverse, iter);

// Get the previous rune from an iterator, or done when at the start of the
// string.
export fn prev(iter: *iterator) (rune | done) = move(iter.reverse, iter);

fn move(forward: bool, iter: *iterator) (rune | done) = {
	let fun = if (forward) &utf8::next else &utf8::prev;
	return match (fun(&iter.dec)) {
	case void => yield done;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case let r: rune =>
		yield r;
	};
};

// Return a substring from the next rune to the end of the string if initialized
// with [[iter]], or the beginning of the string if initialized with [[riter]].
export fn iterstr(iter: *iterator) str = {
	if (iter.reverse) {
		return fromutf8_unsafe(iter.dec.src[..iter.dec.offs]);
	} else {
		return fromutf8_unsafe(iter.dec.src[iter.dec.offs..]);
	};
};

// Return a substring from the position of the first iterator to the position of
// the second iterator. The iterators must originate from the same string and
// the position of the second iterator must not be before the position of the
// first one.
export fn slice(begin: *iterator, end: *iterator) str = {
	assert(begin.dec.src: *[*]u8 == end.dec.src: *[*]u8
		&& begin.dec.offs <= end.dec.offs);
	return fromutf8_unsafe(begin.dec.src[begin.dec.offs..end.dec.offs]);
};

@test fn iter() void = {
	let s = iter("こんにちは");
	assert(prev(&s) is done);
	const expected1 = ['こ', 'ん'];
	for (let i = 0z; i < len(expected1); i += 1) {
		assert(next(&s) as rune == expected1[i]);
	};
	assert(iterstr(&s) == "にちは");
	assert(prev(&s) as rune == 'ん');
	const expected2 = ['ん', 'に', 'ち', 'は'];
	for (let i = 0z; i < len(expected2); i += 1) {
		assert(next(&s) as rune == expected2[i]);
	};
	assert(next(&s) is done);
	assert(next(&s) is done);
	assert(prev(&s) as rune == 'は');

	s = riter("にちは");
	const expected3 = ['は', 'ち', 'に'];
	for (let i = 0z; i < len(expected3); i += 1) {
		assert(next(&s) as rune == expected3[i]);
	};
	assert(next(&s) is done);
	assert(prev(&s) as rune == 'に');
};

@test fn slice() void = {
	let s = iter("こんにちは");
	let t = s;
	assert(len(slice(&s, &t)) == 0 && len(slice(&t, &s)) == 0);
	for (let i = 0; i < 2; i += 1) {
		next(&s);
		next(&t);
	};
	assert(len(slice(&s, &t)) == 0 && len(slice(&t, &s)) == 0);
	for (let i = 0; i < 3; i += 1) {
		next(&t);
	};
	assert(slice(&s, &t) == "にちは");
	for (let i = 0; i < 3; i += 1) {
		next(&s);
	};
	assert(len(slice(&s, &t)) == 0 && len(slice(&t, &s)) == 0);
};
