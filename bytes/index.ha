// Returns the offset of the first instance of 'needle' in a 'haystack' of
// bytes, or void if it is not found.
export fn index(haystack: []u8, needle: u8) (size | void) = {
	for (let i = 0z; i < len(haystack); i += 1z) {
		if (haystack[i] == needle) {
			return i;
		};
	};
};

@test fn index() void = {
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
};
