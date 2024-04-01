// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use sort::cmp;
use strings;

// Converts all ASCII uppercase characters in a string to their lowercase
// representation, returning a new string. The return value must be freed by the
// caller.
export fn strlower(s: str) str = {
	let new: []u8 = alloc([], len(s));
	return strlower_buf(s, new);
};

// Converts all ASCII uppercase characters in a string to their lowercase
// representation, returning a new string. The new string data is stored in the
// supplied buffer. This function will abort if the buffer's length is too small
// to fit the entire string.
export fn strlower_buf(s: str, buf: []u8) str = {
	let it = strings::iter(s);
	for (let r => strings::next(&it)) {
		static append(buf, utf8::encoderune(tolower(r))...);
	};
	return strings::fromutf8(buf)!;
};

// Converts all ASCII lowercase characters in a string to their uppercase
// representation, returning a new string. The return value must be freed by the
// caller.
export fn strupper(s: str) str = {
	let new: []u8 = alloc([], len(s));
	return strupper_buf(s, new);
};

// Converts all ASCII lowercase characters in a string to their uppercase
// representation, returning a new string. The new string data is stored in the
// supplied buffer. This function will abort if the buffer's length is too small
// to fit the entire string.
export fn strupper_buf(s: str, buf: []u8) str = {
	let it = strings::iter(s);
	for (let r => strings::next(&it)) {
		static append(buf, utf8::encoderune(toupper(r))...);
	};
	return strings::fromutf8(buf)!;
};

// Compares two strings by their sort order, treating all ASCII capital letters
// as their lowercase counterpart (i.e. an ASCII-case-insensitive comparison is
// performed). Zero is returned if the strings are equal, a negative value if a
// is less than b, or a positive value if a is greater than b.
export fn strcasecmp(a: str, b: str) int = {
	let abs = strings::toutf8(a);
	let bbs = strings::toutf8(b);
	for (let i = 0z; i < len(abs) && i < len(bbs); i += 1) {
		// you know that i am called "the Cast"...
		// because i *really* love to cast...
		// sometimes i sit and cast all day... ha ha, but
		// sometimes i get carried away!
		let cmp = tolower(abs[i]: rune): u32: int - tolower(bbs[i]: rune): u32: int;
		if (cmp != 0) return cmp;
	};
	return cmp::sizes(&len(abs), &len(bbs));
};

@test fn strcasecmp() void = {
	let s = strupper("ABC");
	defer free(s);
	assert(s == "ABC");

	let s = strlower("ABC");
	defer free(s);
	assert(s == "abc");

	let s = strupper("abc");
	defer free(s);
	assert(s == "ABC");

	let s = strlower("abc");
	defer free(s);
	assert(s == "abc");

	let s = strupper("[[[");
	defer free(s);
	assert(s == "[[[");

	let s = strlower("[[[");
	defer free(s);
	assert(s == "[[[");

	let s = strupper("こ");
	defer free(s);
	assert(s == "こ");

	let s = strlower("こ");
	defer free(s);
	assert(s == "こ");

	assert(strcasecmp("ABC", "ABC") == 0);
	assert(strcasecmp("ABC", "abc") == 0);
	assert(strcasecmp("ABC", "aB") > 0);
	assert(strcasecmp("ab", "Abc") < 0);
	assert(strcasecmp("bcd", "ABC") > 0);
	assert(strcasecmp("ABC", "[[[") > 0);
};
