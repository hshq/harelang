export fn c_strlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0u8; ln += 1z) void;
	return ln;
};

// Wraps a C string in the appropriate Hare structures
export fn from_c(cstr: *const char) const str = {
	const l = c_strlen(cstr);
	const s = struct { // TODO: Use types::string
		data: *[*]u8   = cstr: *[*]u8,
		length: size   = l,
		capacity: size = l,
	};
	return *(&s: *const str);
};
