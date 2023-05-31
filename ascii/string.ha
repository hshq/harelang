// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use encoding::utf8;
use strings;

// Convert all ASCII uppercase characters in a string to their lowercase
// representation, returning a new string. The return value must be freed by the
// caller.
export fn strlower(s: str) str = {
	let new: []u8 = alloc([], len(s));
	let it = strings::iter(s);
	for (true) match (strings::next(&it)) {
	case let r: rune =>
		static append(new, utf8::encoderune(tolower(r))...);
	case void =>
		break;
	};
	return strings::fromutf8(new)!;
};

// Convert all ASCII lowercase characters in a string to their uppercase
// representation, returning a new string. The return value must be freed by the
// caller.
export fn strupper(s: str) str = {
	let new: []u8 = alloc([], len(s));
	let it = strings::iter(s);
	for (true) match (strings::next(&it)) {
	case let r: rune =>
		static append(new, utf8::encoderune(toupper(r))...);
	case void =>
		break;
	};
	return strings::fromutf8(new)!;
};

// Compares two strings by their sort order, treating all ascii capital letters
// as their lowercase counterpart (i.e. an ascii-case-insensitive comparison is
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
		let cmp = tolower(abs[i]: u32: rune): u32: int - tolower(bbs[i]: u32: rune): u32: int;
		if (cmp != 0) return cmp;
	};
	return len(abs): int - len(bbs): int;
};

@test fn strcasecmp() void = {
	let s = strupper("ABC");
	assert(s == "ABC");
	free(s);
	s = strlower("ABC");
	assert(s == "abc");
	free(s);
	s = strupper("abc");
	assert(s == "ABC");
	free(s);
	s = strlower("abc");
	assert(s == "abc");
	free(s);
	s = strupper("[[[");
	assert(s == "[[[");
	free(s);
	s = strlower("[[[");
	assert(s == "[[[");
	free(s);
	s = strupper("こ");
	assert(s == "こ");
	free(s);
	s = strlower("こ");
	assert(s == "こ");
	free(s);

	assert(strcasecmp("ABC", "ABC") == 0);
	assert(strcasecmp("ABC", "abc") == 0);
	assert(strcasecmp("ABC", "aB") > 0);
	assert(strcasecmp("ab", "Abc") < 0);
	assert(strcasecmp("bcd", "ABC") > 0);
	assert(strcasecmp("ABC", "[[[") > 0);
};
