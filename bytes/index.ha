// Returns the offset of the first instance of 'needle' in a 'haystack' of
// bytes, or void if it is not found.
export fn index(haystack: []u8, needle: (u8 | []u8)) (size | void) = {
	return match (needle) {
		b: u8   => index_byte(haystack, b),
		b: []u8 => index_slice(haystack, b),
	};
};

fn index_byte(haystack: []u8, needle: u8) (size | void) = {
	for (let i = 0z; i < len(haystack); i += 1) {
		if (haystack[i] == needle) {
			return i;
		};
	};
};

fn index_slice(haystack: []u8, needle: []u8) (size | void) = {
	for (let i = 0z; i + len(needle) <= len(haystack); i += 1) {
		if (equal(haystack[i..i + len(needle)], needle)) {
			return i;
		};
	};
};


@test fn index() void = {
	// Bytes
	const a: [4]u8 = [1, 3, 3, 7];
	match (index(a, 7)) {
		n: size => assert(n == 3),
		void => abort(),
	};
	match (index(a, 42)) {
		size => abort(),
		void => void,
	};
	match (index([], 42)) {
		size => abort(),
		void => void,
	};

	// Slices
	match (index(a, [3, 3])) {
		n: size => assert(n == 1),
		void => abort(),
	};
	match (index(a, [])) {
		n: size => assert(n == 0),
		void => abort(),
	};
	match(index(a, [4, 2])) {
		size => abort(),
		void => void,
	};

	const special: []u8 = [1, 1, 1, 2];
	match (index(special, [1, 1, 2])) {
		n: size => assert(n == 1),
		void => abort(),
	};
};
