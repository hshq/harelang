use encoding::utf8;

// An iterator which yields each rune from a string.
export type iterator = struct {
	dec:  utf8::decoder,
	push: (rune | void),
};

// Initializes a string iterator, starting at the beginning of the string.
export fn iter(src: str) iterator = iterator {
	dec = utf8::decode(src),
	push = void,
};

// Initializes a string iterator, starting at the end of the string.
export fn riter(src: str) iterator = {
	let ret = iterator {
		dec = utf8::decode(src),
		push = void,
	};
	ret.dec.offs = len(src);
	return ret;
};

// Get the next rune from an iterator, or void if there are none left.
//
// Be aware that a rune is not the minimum lexographical unit of language in
// Unicode strings. If you use these runes to construct a new string,
// reordering, editing, or omitting any of the runes without careful discretion
// may cause linguistic errors to arise. To avoid this, you may need to use
// [[unicode::graphiter]] instead.
export fn next(iter: *iterator) (rune | void) = {
	match (iter.push) {
	case r: rune =>
		iter.push = void;
		return r;
	case void => void;
	};
	return match (utf8::next(&iter.dec)) {
	case void => void;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case r: rune =>
		yield r;
	};
};

// Get the previous rune from an iterator, or void when at the start of the
// string.
export fn prev(iter: *iterator) (rune | void) = {
	assert(iter.push is void);
	return match (utf8::prev(&iter.dec)) {
	case void =>
		yield void;
	case (utf8::more | utf8::invalid) =>
		abort("Invalid UTF-8 string (this should not happen)");
	case r: rune =>
		yield r;
	};
};

// Causes the next call to [[next]] to return the provided rune, effectively
// un-reading it. The next call using this iterator *must* be [[next]]; all other
// functions will cause the program to abort until the pushed rune is consumed.
// This does not modify the underlying string, and as such, subsequent calls to
// functions like [[prev]] or [[iter_str]] will behave as if push were never called.
export fn push(iter: *iterator, r: rune) void = {
	assert(iter.push is void);
	iter.push = r;
};

// Return a substring from the next rune to the end of the string.
export fn iter_str(iter: *iterator) str = {
	assert(iter.push is void);
	return fromutf8(iter.dec.src[iter.dec.offs..]);
};

@test fn iter() void = {
	let s = iter("こんにちは");
	assert(prev(&s) is void);
	const expected1 = ['こ', 'ん'];
	for (let i = 0z; i < len(expected1); i += 1) {
		match (next(&s)) {
		case r: rune =>
			assert(r == expected1[i]);
		case void =>
			abort();
		};
	};
	assert(iter_str(&s) == "にちは");
	assert(prev(&s) as rune == 'ん');
	const expected2 = ['ん', 'に', 'ち', 'は'];
	for (let i = 0z; i < len(expected2); i += 1) {
		match (next(&s)) {
		case r: rune =>
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
	for (let i = 0z; i< len(expected3); i += 1) {
		match (prev(&s)) {
		case r: rune =>
			assert(r == expected3[i]);
		case void =>
			abort();
		};
	};
	assert(prev(&s) is void);
	assert(next(&s) as rune == 'に');
};

// Returns a slice of runes for a string in O(n). The caller must free the
// return value.
export fn runes(s: str) []rune = {
	let sl: []rune = alloc([], len(s));
	let iter = iter(s);
	for (true) {
		match (next(&iter)) {
		case void => break;
		case r: rune =>
			append(sl, r);
		};
	};
	return sl;
};
