use types;

// Computes the length of a NUL-terminated C string, in octets, in O(n). The
// computed length does not include the NUL terminator.
export fn c_strlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0u8; ln += 1z) void;
	return ln;
};

// Converts a C string to a Hare string in O(n).
export fn from_c(cstr: *const char) const str = {
	// TODO: Validate UTF-8?
	const l = c_strlen(cstr);
	const s = types::string {
		data     = cstr: *[*]u8,
		length   = l,
		capacity = l,
	};
	return *(&s: *const str);
};
