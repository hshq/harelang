// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use strings;

// Compares two strings by their ASCII sort order, treating all capital letters
// as their lowercase counterpart (i.e. a case-insensitive comparison is
// performed). Zero is returned if the strings are equal, a negative value if a
// is less than b, or a positive value if a is greater than b. Aborts if a
// non-ASCII byte is encountered.
export fn strcasecmp(a: str, b: str) int = {
	let a = strings::iter(a), b = strings::iter(b);
	for (true) {
		let ra = match (strings::next(&a)) {
		case void =>
			match (strings::next(&b)) {
			case void =>
				break;
			case rune =>
				return -1;
			};
		case let r: rune =>
			yield r;
		};
		let rb = match (strings::next(&b)) {
		case void =>
			return 1;
		case let r: rune =>
			yield r;
		};
		assert(valid(ra) && valid(rb));
		let ra = tolower(ra), rb = tolower(rb);
		if (ra != rb) {
			return ra: u32: int - rb: u32: int;
		};
	};
	return 0;
};

@test fn strcmp() void = {
	assert(strcasecmp("ABC", "ABC") == 0);
	assert(strcasecmp("ABC", "abc") == 0);
	assert(strcasecmp("ABC", "aB") > 0);
	assert(strcasecmp("ab", "Abc") < 0);
	assert(strcasecmp("bcd", "ABC") > 0);
	assert(strcasecmp("ABC", "[[[") > 0);
};
