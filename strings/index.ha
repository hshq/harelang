use bytes;

// Returns the index of the first occurance of 'needle' in the 'haystack', or
// void if not present. The index returned is the rune-wise index, not the
// byte-wise index.
export fn index(haystack: str, needle: (str | rune)) (size | void) = {
	match (needle) {
	case r: rune =>
		return index_rune(haystack, r);
	case s: str =>
		return index_string(haystack, s);
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

fn index_string(s: str, needle: str) (size | void) = {
	let s_iter = iter(s);
	for (let i = 0z; true; i += 1) {
		let rest_iter = s_iter;
		let needle_iter = iter(needle);
		for (true) {
			const rest_rune = next(&rest_iter);
			const needle_rune = next(&needle_iter);
			if (rest_rune is void && !(needle_rune is void)) {
				break;
			};
			if (needle_rune is void) {
				return i;
			};
			if ((rest_rune as rune) != (needle_rune as rune)) {
				break;
			};
		};
		if (next(&s_iter) is void) {
			break;
		};
	};
};

@test fn index() void = {
	assert(index("hello world", 'w') as size == 6);
	assert(index("こんにちは", 'ち') as size == 3);
	assert(index("こんにちは", 'q') is void);

	assert(index("hello", "hello") as size == 0);
	assert(index("hello world!", "hello") as size == 0);
	assert(index("hello world!", "world") as size == 6);
	assert(index("hello world!", "orld!") as size == 7);
	assert(index("hello world!", "word") is void);
	assert(index("こんにちは", "ちは") as size == 3);
	assert(index("こんにちは", "きょうは") is void);
};
