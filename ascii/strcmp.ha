use strings;

// Compares two strings by their ASCII sort order. If either string is not
// entirely composed of ASCII characters, void is returned. Otherwise, zero is
// returned if the strings are equal, a negative value if a is less than b, or a
// positive value if a is greater than b.
export fn strcmp(a: str, b: str) (int | void) = {
	let a = strings::iter(a), b = strings::iter(b);
	for (true) {
		let ra = match (strings::next(&a)) {
		case void =>
			match (strings::next(&b)) {
			case void =>
				return 0;
			case rune =>
				return -1;
			};
		case r: rune =>
			yield r;
		};
		let rb = match (strings::next(&b)) {
		case void =>
			return 1;
		case r: rune =>
			yield r;
		};
		if (!isascii(ra) || !isascii(rb)) {
			return;
		};
		if (ra != rb) {
			return ra: u32: int - rb: u32: int;
		};
	};
};

// Similar to [[strcmp]], but compares strings irrespective of their uppercase or
// lowercase classification within the ASCII character set.
export fn strcasecmp(a: str, b: str) (int | void) = {
	let a = strings::iter(a), b = strings::iter(b);
	for (true) {
		let ra = match (strings::next(&a)) {
		case void =>
			match (strings::next(&b)) {
			case void =>
				return 0;
			case rune =>
				return -1;
			};
		case r: rune =>
			yield r;
		};
		let rb = match (strings::next(&b)) {
		case void =>
			return 1;
		case r: rune =>
			yield r;
		};
		if (!isascii(ra) || !isascii(rb)) {
			return;
		};
		let ra = tolower(ra), rb = tolower(rb);
		if (ra != rb) {
			return ra: u32: int - rb: u32: int;
		};
	};
};

@test fn strcmp() void = {
	assert(strcmp("ABC", "ABC") as int == 0);
	assert(strcmp("ABC", "AB") as int == 1);
	assert(strcmp("AB", "ABC") as int == -1);
	assert(strcmp("BCD", "ABC") as int == 1);
	assert(strcmp("ABC", "こんにちは") is void);
	assert(strcmp("ABC", "abc") as int != 0);
	assert(strcasecmp("ABC", "abc") as int == 0);
};
