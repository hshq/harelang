// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use strings;

// Convert all ascii uppercase characters in a string to their lowercase
// representation. Modifies the original string.
export fn strlower(s: str) str = {
	let bs = strings::toutf8(s);
	for (let i = 0z; i < len(bs); i += 1) {
		if (bs[i] < 128 && cclass[bs[i]] & U != 0) {
			bs[i] += 'a': u8 - 'A';
		};
	};
	return s;
};

// Convert all ascii lowercase characters in a string to their uppercase
// representation. Modifies the original string.
export fn strupper(s: str) str = {
	let bs = strings::toutf8(s);
	for (let i = 0z; i < len(bs); i += 1) {
		if (bs[i] < 128 && cclass[bs[i]] & L != 0) {
			bs[i] -= 'a': u8 - 'A';
		};
	};
	return s;
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
	assert(strupper("ABC") == "ABC");
	assert(strlower("ABC") == "abc");
	assert(strupper("abc") == "ABC");
	assert(strlower("abc") == "abc");
	assert(strupper("[[[") == "[[[");
	assert(strlower("[[[") == "[[[");
	assert(strupper("こ") == "こ");
	assert(strlower("こ") == "こ");

	assert(strcasecmp("ABC", "ABC") == 0);
	assert(strcasecmp("ABC", "abc") == 0);
	assert(strcasecmp("ABC", "aB") > 0);
	assert(strcasecmp("ab", "Abc") < 0);
	assert(strcasecmp("bcd", "ABC") > 0);
	assert(strcasecmp("ABC", "[[[") > 0);
};
