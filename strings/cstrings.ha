// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use encoding::utf8;
use types;

// Computes the length of a NUL-terminated C string, in octets, in O(n). The
// computed length does not include the NUL terminator.
export fn cstrlen(cstr: *const char) size = {
	const ptr = cstr: *[*]u8;
	let ln = 0z;
	for (ptr[ln] != 0; ln += 1) void;
	return ln;
};

// Converts a C string to a Hare string in O(n), and does not check if it's
// valid UTF-8.
export fn fromc_unsafe(cstr: *const char) const str = {
	const l = cstrlen(cstr);
	const s = types::string {
		data = cstr: *[*]u8,
		length = l,
		capacity = l + 1,
	};
	return *(&s: *const str);
};

// Converts a C string to a Hare string in O(n). If the string is not valid
// UTF-8, abort.
export fn fromc(cstr: *const char) (const str | utf8::invalid) = {
	let s = fromc_unsafe(cstr);
	return if (utf8::valid(s)) s else utf8::invalid;
};

// Converts a Hare string to a C string. The result is allocated; the caller
// must free it when they're done.
export fn to_c(s: const str) *char = {
	let slice: []u8 = alloc([0...], len(s) + 1);
	return to_cbuf(s, slice);
};

// Converts a Hare string to a C string. The result is stored into a
// user-supplied buffer.
export fn to_cbuf(s: const str, sl: []u8) *char = {
	if (len(sl) < len(s) + 1) {
		abort("to_cbuf: buffer has insufficient space for string plus NUL");
	};

	const s = &s: *[]u8;
	sl[..len(s)] = s[..];
	sl[len(s)] = 0;

	return (*(&sl: *types::slice)).data: *char;
};
