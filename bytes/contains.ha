// Returns true if a byte slice contains a byte or a sequence of bytes.
export fn contains(haystack: []u8, needle: (u8 | []u8)) bool = match (needle) {
case b: u8 =>
	yield !(index_byte(haystack, b) is void);
case b: []u8 =>
	yield !(index_slice(haystack, b) is void);
};
