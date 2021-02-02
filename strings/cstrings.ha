use encoding::utf8;
use types;

// Computes the length of a NUL-terminated C string, in octets, in O(n). The
// computed length does not include the NUL terminator.
export fn c_strlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0u8; ln += 1z) void;
	return ln;
};

// Converts a C string to a Hare string in O(n), and does not check if it's
// valid UTF-8.
export fn from_c_unsafe(cstr: *const char) const str = {
	const l = c_strlen(cstr);
	const s = types::string {
		data     = cstr: *[*]u8,
		length   = l,
		capacity = l,
	};
	return *(&s: *const str);
};

// Converts a C string to a Hare string in O(n). If the string is not valid
// UTF-8, abort.
export fn from_c(cstr: *const char) const str = {
	let s = from_c_unsafe(cstr);
	assert(utf8::valid(s));
	return s;
};
