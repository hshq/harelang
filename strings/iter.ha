// License: MPL-2.0
// (c) 2022 Ajay R <ar324@protonmail.com>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Miccah Castorina <contact@miccah.io>
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
	dec = utf8::decode(src),
	reverse = false,
};

// Initializes a string iterator, starting at the end of the string and moving
// backwards with each call to [[next]].
export fn riter(src: str) iterator = {
	let ret = iterator {
		dec = utf8::decode(src),
		reverse = true,
	};
	ret.dec.offs = len(src);
	return ret;
};

// Get the next rune from an iterator, or void if there are none left.
//
// Be aware that a rune is not the minimum lexographical unit of language in
// Unicode strings. If you use these runes to construct a new string,
// reordering, editing, or omitting any of the runes without careful discretion
// may cause linguistic errors to arise. To avoid this, you may need to use a
// third-party Unicode module instead.
export fn next(iter: *iterator) (rune | void) = {
	if (iter.reverse) {
		return next_backward(iter);
	 } else {
		return next_forward(iter);
	 };
};

fn next_forward(iter: *iterator) (rune | void) = {
	return match (utf8::next(&iter.dec)) {
	case void => void;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case let r: rune =>
		yield r;
	};
};

// Get the previous rune from an iterator, or void when at the start of the
// string.
export fn prev(iter: *iterator) (rune | void) = {
	if (iter.reverse) {
		return next_forward(iter);
	 } else {
		return next_backward(iter);
	 };
};

fn next_backward(iter: *iterator) (rune | void) = {
	return match (utf8::prev(&iter.dec)) {
	case void =>
		yield void;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case let r: rune =>
		yield r;
	};
};

// Return a substring from the next rune to the end of the string.
export fn iterstr(iter: *iterator) str = {
	return fromutf8(iter.dec.src[iter.dec.offs..])!;
};

@test fn iter() void = {
	let s = iter("こんにちは");
	assert(prev(&s) is void);
	const expected1 = ['こ', 'ん'];
	for (let i = 0z; i < len(expected1); i += 1) {
		match (next(&s)) {
		case let r: rune =>
			assert(r == expected1[i]);
		case void =>
			abort();
		};
	};
	assert(iterstr(&s) == "にちは");
	assert(prev(&s) as rune == 'ん');
	const expected2 = ['ん', 'に', 'ち', 'は'];
	for (let i = 0z; i < len(expected2); i += 1) {
		match (next(&s)) {
		case let r: rune =>
			assert(r == expected2[i]);
		case void =>
			abort();
		};
	};
	assert(next(&s) is void);
	assert(next(&s) is void);
	assert(prev(&s) as rune == 'は');

	s = riter("にちは");
	const expected3 = ['は', 'ち', 'に'];
	for (let i = 0z; i < len(expected3); i += 1) {
		match (next(&s)) {
		case let r: rune =>
			assert(r == expected3[i]);
		case void =>
			abort();
		};
	};
	assert(next(&s) is void);
	assert(prev(&s) as rune == 'に');
};
