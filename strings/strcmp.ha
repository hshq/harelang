// Compares two strings by their Unicode codepoint sort order. Zero is returned
// if the strings are equal, a negative value if a is less than b, or a positive
// value if a is greater than b.
export fn strcmp(a: str, b: str) int = {
	let a = iter(a), b = iter(b);
	for (true) {
		let ra = match (next(&a)) {
		case void =>
			match (next(&b)) {
			case void =>
				return 0;
			case rune =>
				return -1;
			};
		case let r: rune =>
			yield r;
		};
		let rb = match (next(&b)) {
		case void =>
			return 1;
		case let r: rune =>
			yield r;
		};
		if (ra != rb) {
			return ra: u32: int - rb: u32: int;
		};
	};
	abort("unreachable");
};

@test fn strcmp() void = {
	assert(strcmp("ABC", "ABC") == 0);
	assert(strcmp("ABC", "AB") > 0);
	assert(strcmp("AB", "ABC") < 0);
	assert(strcmp("BCD", "ABC") > 0);
	assert(strcmp("ABC", "こんにちは") < 0);
	assert(strcmp("ABC", "abc") < 0);
};
