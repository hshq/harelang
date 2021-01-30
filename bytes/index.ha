// Returns the offset of the first instance of 'needle' in a 'haystack' of
// bytes, or void if it is not found.
export fn index(haystack: []u8, needle: u8) (size | void) = {
	for (let i = 0z; i < len(haystack); i += 1z) {
		if (haystack[i] == needle) {
			return i;
		};
	};
};
