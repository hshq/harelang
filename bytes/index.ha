// Returns the offset of the first instance of 'needle' in a 'haystack' of
// bytes, or void if it is not found.
export fn index(haystack: []u8, needle: (u8 | []u8)) (size | void) = {
	return match (needle) {
		b: u8   => index_byte(haystack, b),
		b: []u8 => index_slice(haystack, b),
	};
};

fn index_byte(haystack: []u8, needle: u8) (size | void) = {
	for (let i = 0z; i < len(haystack); i += 1z) {
		if (haystack[i] == needle) {
			return i;
		};
	};
};

fn index_slice(haystack: []u8, needle: []u8) (size | void) = {
	if (len(needle) > len(haystack)) {
		return;
	};
	let i = 0z;
	for (i < len(haystack)) {
		let n = nequal(haystack[i..], needle);
		if (n == len(needle)) {
			return i;
		} else if (n != 0z) {
			i += n;
		} else {
			i += 1z;
		};
	};
};


@test fn index() void = {
	// Bytes
	let a: [4]u8 = [1u8, 3u8, 3u8, 7u8];
	match (index(a, 7u8)) {
		n: size => assert(n == 3z),
		void => abort(),
	};
	match (index(a, 42u8)) {
		size => abort(),
		void => void,
	};
	match (index([], 42u8)) {
		size => abort(),
		void => void,
	};

	// Slices
	match (index(a, [3u8, 3u8])) {
		n: size => assert(n == 1z),
		void => abort(),
	};
	match (index(a, [])) {
		n: size => assert(n == 0z),
		void => abort(),
	};
	match(index(a, [4u8, 2u8])) {
		size => abort(),
		void => void,
	};
};
