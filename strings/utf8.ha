use encoding::utf8;
use types;

// Converts a byte slice into a string WITHOUT checking that the byte slice is a
// valid UTF-8 string.
export fn from_utf8_unsafe(in: []u8) str = {
	const s = types::string {
		data     = in: *[*]u8,
		length   = len(in),
		capacity = len(in),
	};
	return *(&s: *const str);
};

// Converts a byte slice into a string. Aborts if the bytes contain invalid
// UTF-8. To handle such an error without aborting, see
// [encoding::utf8::decode] instead.
export fn from_utf8(in: []u8) str = {
	let s = from_utf8_unsafe(in);
	assert(utf8::valid(s));
	return s;
};

// Converts a string to a UTF-8 slice.
export fn to_utf8(in: str) []u8 = *(&in: *[]u8);
