// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>

// Returns true if a byte slice contains a byte or a sequence of bytes.
export fn contains(haystack: []u8, needle: (u8 | []u8)) bool = match (needle) {
case let b: u8 =>
	yield !(index_byte(haystack, b) is void);
case let b: []u8 =>
	yield !(index_slice(haystack, b) is void);
};

// Returns true if "in" has the given prefix, false otherwise
export fn hasprefix(in: []u8, prefix: []u8) bool = {
	return if (len(in) < len(prefix)) false
		else equal(in[..len(prefix)], prefix);
};

@test fn hasprefix() void = {
	const cases: []([]u8, []u8, bool) = [
		([], [], true),
		([0], [], true),
		([], [0], false),
		([1, 2, 3], [1, 2], true),
		([1, 2, 3], [1, 1], false),
		([1, 2, 3], [1, 2, 3, 4], false),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		let s = cases[i].0;
		let prefix = cases[i].1;
		let expected = cases[i].2;
		let actual = hasprefix(s, prefix);
		assert(actual == expected);
	};
};

// Returns true if "in" has the given suffix, false otherwise
export fn hassuffix(in: []u8, suffix: []u8) bool = {
	return if (len(in) < len(suffix)) false
		else equal(in[len(in) - len(suffix)..], suffix);
};

@test fn hassuffix() void = {
	const cases: []([]u8, []u8, bool) = [
		([], [], true),
		([0], [], true),
		([], [0], false),
		([1, 2, 3], [2, 3], true),
		([1, 2, 3], [2, 2], false),
		([1, 2, 3, 4], [2, 3, 4], true),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		let s = cases[i].0;
		let prefix = cases[i].1;
		let expected = cases[i].2;
		let actual = hassuffix(s, prefix);
		assert(actual == expected);
	};
};
