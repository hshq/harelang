// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Returns the offset of the first instance of "needle" in a "haystack" of
// bytes, or void if it is not found.
export fn index(haystack: []u8, needle: (u8 | []u8)) (size | void) = {
	return match (needle) {
	case let b: u8 =>
		yield index_byte(haystack, b);
	case let b: []u8 =>
		yield index_slice(haystack, b);
	};
};

fn index_byte(haystack: []u8, needle: u8) (size | void) = {
	for (let i = 0z; i < len(haystack); i += 1) {
		if (haystack[i] == needle) {
			return i;
		};
	};
};

fn index_2bytes(haystack: []u8, needle: u16) (size | void) = {
	if (len(haystack) > 1) {
		let x = haystack[0]: u16;
		for (let i = 1z; i < len(haystack); i += 1) {
			x = x << 8 | haystack[i];
			if (x == needle) {
				return i - 1;
			};
		};
	};
};

fn index_3bytes(haystack: []u8, needle: u32) (size | void) = {
	if (len(haystack) > 2) {
		let x = haystack[0]: u32 << 8 | haystack[1];
		for (let i = 2z; i < len(haystack); i += 1) {
			x = x << 16 >> 8 | haystack[i];
			if (x == needle) {
				return i - 2;
			};
		};
	};
};

fn index_4bytes(haystack: []u8, needle: u32) (size | void) = {
	if (len(haystack) > 3) {
		let x = haystack[0]: u32 << 16 |
			haystack[1]: u32 << 8 |
			haystack[2];
		for (let i = 3z; i < len(haystack); i += 1) {
			x = x << 8 | haystack[i];
			if (x == needle) {
				return i - 3;
			};
		};
	};
};

fn index_slice(haystack: []u8, b: []u8) (size | void) = {
	switch (len(b)) {
	case 0 =>
		return 0;
	case 1 =>
		return index_byte(haystack, b[0]);
	case 2 =>
		return index_2bytes(haystack, b[0]: u16 << 8 | b[1]);
	case 3 =>
		return index_3bytes(
			haystack,
			b[0]: u32 << 16 | b[1]: u32 << 8 | b[2],
		);
	case 4 =>
		return index_4bytes(
			haystack,
			b[0]: u32 << 24 | b[1]: u32 << 16 | b[2]: u32 << 8 | b[3],
		);
	case =>
		return index_tw(haystack, b);
	};
};

// Returns the offset of the last instance of "needle" in a "haystack" of
// bytes, or void if it is not found.
export fn rindex(haystack: []u8, needle: (u8 | []u8)) (size | void) = {
	match (needle) {
	case let b: u8 =>
		return rindex_byte(haystack, b);
	case let b: []u8 =>
		return rindex_slice(haystack, b);
	};
};

fn rindex_byte(haystack: []u8, needle: u8) (size | void) = {
	for (let i = len(haystack); i > 0; i -= 1) {
		if (haystack[i - 1] == needle) {
			return i - 1;
		};
	};
};

fn rindex_slice(haystack: []u8, needle: []u8) (size | void) = {
	for (let i = 0z; i + len(needle) <= len(haystack); i += 1) {
		let r = len(haystack) - i;
		if (equal(haystack[r - len(needle)..r], needle)) {
			return r - len(needle);
		};
	};
};

@test fn index() void = {
	// Bytes
	const a: [4]u8 = [1, 3, 3, 7];
	assert(index(a, 7) as size == 3);
	assert(index(a, 42) is void);
	assert(index([], 42) is void);

	assert(rindex(a, 3) as size == 2);
	assert(rindex(a, 42) is void);
	assert(rindex([], 42) is void);

	// Slices
	const a: [4]u8 = [1, 1, 1, 2];
	assert(rindex(a, [1, 1]) as size == 1);
	assert(rindex(a, [1, 2]) as size == 2);

	// len(haystack) < len(needle)
	assert(index([], [1, 2, 3]) is void);
	assert(index([1, 2, 3], [1, 2, 3, 4]) is void);

	// len(haystack) == len(needle)
	assert(index([42, 20], [42, 20]) as size == 0);
	assert(index([1, 1, 1, 2], [1, 1, 1, 3]) is void);

	assert(index([1, 42, 24], [42, 24]) as size == 1);
	assert(index([1, 3, 3, 7], [3, 3]) as size == 1);
	assert(index([1, 1, 1, 2], [1, 1, 2]) as size == 1);
	assert(index([1, 1, 1, 3, 2], [1, 1, 1, 2]) is void);

	const tests: [_](str, str) = [
		("3214567844", "0123456789"),
		("3214567889012345", "0123456789012345"),
		("32145678890123456789", "01234567890123456789"),
		("32145678890123456789012345678901234567890211", "01234567890123456789012345678901"),
		("321456788901234567890123456789012345678911", "0123456789012345678901234567890"),
		("abc", "x"),
		("oxoxoxoxoxoxoxoxoxoxoxox", "oy"),
		("x", "a"),
		("x01234567x89", "0123456789"),
		("xabcqxq", "abcqq"),
		("xabxc", "abc"),
		("xabxcqq", "abcqq"),
		("xbc", "abc"),
		("xbcd", "abcd"),
		("xx012345678901234567890123456789012345678901234567890123456789012", "0123456789012345678901234567890123456xxx"),
		("xyz012345678", "0123456789"),
		("xyz0123456789012345678", "01234567890123456789"),
		("xyz0123456789012345678901234567890", "01234567890123456789012345678901"),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let haystack = *(&tests[i].0: *[]u8);
		let needle = *(&tests[i].1: *[]u8);
		index(haystack, needle) as void;
	};

	const tests: [_](str, str, size) = [
		("", "", 0),
		("01234567", "01234567", 0),
		("0123456789", "0123456789", 0),
		("0123456789012345", "0123456789012345", 0),
		("01234567890123456789", "01234567890123456789", 0),
		("0123456789012345678901234567890", "0123456789012345678901234567890", 0),
		("01234567890123456789012345678901", "01234567890123456789012345678901", 0),
		("ab", "ab", 0),
		("abc", "a", 0),
		("abc", "abc", 0),
		("abc", "b", 1),
		("abc", "c", 2),
		("abcABCabc", "A", 3),
		("abcd", "abcd", 0),
		("abcqq", "abcqq", 0),
		("barfoobarfoo", "foo", 3),
		("foo", "", 0),
		("foo", "foo", 0),
		("foo", "o", 1),
		("oofofoofooo", "f", 2),
		("oofofoofooo", "foo", 4),
		("oxoxoxoxoxoxoxoxoxoxoxoy", "oy", 22),
		("x", "x", 0),
		("x01234567", "01234567", 1),
		("x0123456789", "0123456789", 1),
		("x0123456789012345", "0123456789012345", 1),
		("x01234567890123456789", "01234567890123456789", 1),
		("x0123456789012345678901234567890", "0123456789012345678901234567890", 1),
		("x01234567890123456789012345678901", "01234567890123456789012345678901", 1),
		("x0123456789012345678901234567890x01234567890123456789012345678901", "01234567890123456789012345678901", 33),
		("x012345678901234567890123456789x0123456789012345678901234567890", "0123456789012345678901234567890", 32),
		("x0123456789012345678x01234567890123456789", "01234567890123456789", 21),
		("x012345678901234x0123456789012345", "0123456789012345", 17),
		("x012345678x0123456789", "0123456789", 11),
		("x0123456x01234567", "01234567", 9),
		("xab", "ab", 1),
		("xabc", "abc", 1),
		("xabcd", "abcd", 1),
		("xabcqq", "abcqq", 1),
		("xx012345678901234567890123456789012345678901234567890123456789012", "0123456789012345678901234567890123456789", 2),
		("xx0123456789012345678901234567890123456789012345678901234567890120123456789012345678901234567890123456xxx", "0123456789012345678901234567890123456xxx", 65),
		("xxxxxx012345678901234567890123456789012345678901234567890123456789012", "012345678901234567890123456789012345678901234567890123456789012", 6),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		let haystack = *(&tests[i].0: *[]u8);
		let needle = *(&tests[i].1: *[]u8);
		assert(index(haystack, needle) as size == tests[i].2);
	};
};
