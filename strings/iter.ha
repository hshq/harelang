// License: MPL-2.0
// (c) 2022 Ajay R <ar324@protonmail.com>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Miccah Castorina <contact@miccah.io>
use encoding::utf8;

export type iterator = struct {
	dec:  utf8::decoder,
	push: (rune | void),
	next: *fn(_: *utf8::decoder) (rune | void | utf8::more | utf8::invalid),
	prev: *fn(_: *utf8::decoder) (rune | void | utf8::more | utf8::invalid),
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
	push = void,
	next = &utf8::next,
	prev = &utf8::prev,
};

// Initializes a string iterator, starting at the end of the string and moving
// backwards with each call to [[next]].
export fn riter(src: str) iterator = {
	// TODO: Add rnext et al to avoid blowing up the stack footprint with
	// next/prev pointers
	let ret = iterator {
		dec = utf8::decode(src),
		push = void,
		next = &utf8::prev,
		prev = &utf8::next,
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
	match (iter.push) {
	case let r: rune =>
		iter.push = void;
		return r;
	case void => void;
	};
	return match (iter.next(&iter.dec)) {
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
	assert(iter.push is void);
	return match (iter.prev(&iter.dec)) {
	case void =>
		yield void;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case let r: rune =>
		yield r;
	};
};

// Causes the next call to [[next]] to return the provided rune, effectively
// un-reading it. The next call using this iterator *must* be [[next]]; all other
// functions will cause the program to abort until the pushed rune is consumed.
// This does not modify the underlying string, and as such, subsequent calls to
// functions like [[prev]] or [[iterstr]] will behave as if push were never called.
export fn push(iter: *iterator, r: rune) void = {
	// TODO: This should probably be removed, and the push field removed
	// from the struct.
	assert(iter.push is void);
	iter.push = r;
};

// Return a substring from the next rune to the end of the string.
export fn iterstr(iter: *iterator) str = {
	assert(iter.push is void);
	return fromutf8(iter.dec.src[iter.dec.offs..]);
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
	push(&s, 'q');
	assert(next(&s) as rune == 'q');
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
