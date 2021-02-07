// Returns true if a byte slice contains a byte or a sequence of bytes.
export fn contains(haystack: []u8, needle: (u8 | []u8)) bool = match (needle) {
	b: u8   => !(index_byte(haystack, b) is void),
	b: []u8 => !(index_slice(haystack, b) is void),
};
