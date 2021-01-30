// Computes the length of a NUL-terminated C string, in octets, in O(n). The
// computed length not include the NUL terminator in the length.
export fn c_strlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0u8; ln += 1z) void;
	return ln;
};

// Converts a C string to a Hare string in O(n).
export fn from_c(cstr: *const char) const str = {
	const l = c_strlen(cstr);
	const s = struct { // TODO: Use types::string
		data: *[*]u8   = cstr: *[*]u8,
		length: size   = l,
		capacity: size = l,
	};
	return *(&s: *const str);
};
