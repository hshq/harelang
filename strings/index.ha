use bytes;

// Returns the index of the first occurance of 'needle' in the 'haystack', or
// void if not present. The index returned is the rune-wise index, not the
// byte-wise index.
export fn index(haystack: str, needle: (str | rune)) (size | void) = {
	match (needle) {
	case r: rune =>
		return index_rune(haystack, r);
	case s: str =>
		abort(); // TODO
	};
};

fn index_rune(s: str, r: rune) (size | void) = {
	let iter = iter(s);
	for (let i = 0z; true; i += 1) {
		match (next(&iter)) {
		case n: rune =>
			if (r == n) {
				return i;
			};
		case void =>
			break;
		};
	};
};

@test fn index() void = {
	assert(index("hello world", 'w') as size == 6);
	assert(index("こんにちは", 'ち') as size == 3);
	assert(index("こんにちは", 'q') is void);
};
