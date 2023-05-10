use encoding::utf8;
use types;

// Computes the length of a NUL-terminated C string, in octets, in O(n). The
// computed length does not include the NUL terminator.
export fn strlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0; ln += 1) void;
	return ln;
};

// Converts a C string to a Hare string in O(n), and does not check if it's
// valid UTF-8.
export fn tostr_unsafe(cstr: *const char) const str = {
	const l = strlen(cstr);
	const s = types::string {
		data = cstr: *[*]u8,
		length = l,
		capacity = l + 1,
	};
	return *(&s: *const str);
};

// Converts a C string to a Hare string in O(n). If the string is not valid
// UTF-8, return [[encoding::utf8::invalid]].
export fn tostr(cstr: *const char) (const str | utf8::invalid) = {
	let s = tostr_unsafe(cstr);
	return if (utf8::valid(s)) s else utf8::invalid;
};

// Converts a Hare string to a C string. The result is allocated; the caller
// must free it when they're done.
export fn fromstr(s: const str) *char = {
	let slice: []char = alloc([0...], len(s) + 1);
	return fromstr_buf(s, slice);
};

// Converts a Hare string to a C string. The result is stored into a
// user-supplied buffer.
export fn fromstr_buf(s: const str, sl: []char) *char = {
	if (len(sl) < len(s) + 1) {
		abort("types::c::fromstr_buf: buffer has insufficient space for string plus NUL");
	};

	const s = &s: *[]char;
	sl[..len(s)] = s[..];
	sl[len(s)] = 0;

	return (*(&sl: *types::slice)).data: *char;
};
