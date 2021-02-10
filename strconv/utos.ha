use bytes;
use types;

// Converts a u64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u64tos(u: u64) const str = {
	static assert(types::U64_MAX == 18446744073709551615);
	static let buf: [21]u8 = [0...]; // 20 digits plus NUL
	buf = [0...];

	let s = types::string { data = &buf, ... };
	if (u == 0) {
		s.data[s.length] = '0': u32: u8;
		s.length += 1z;
	};

	for (u > 0u64) {
		s.data[s.length] = '0': u32: u8 + (u % 10): u8;
		s.length += 1;
		u /= 10;
	};

	bytes::reverse(s.data[..s.length]);
	s.data[s.length] = 0;
	return *(&s: *str);
};

// Converts a u8 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u8tos(u: u8) const str = u64tos(u: u64);

// Converts a u16 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u16tos(u: u16) const str = u64tos(u: u64);

// Converts a u32 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u32tos(u: u32) const str = u64tos(u: u64);

// Converts a uint to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn utos(u: uint) const str = u64tos(u: u64);

// Converts a size to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
export fn ztos(z: size) const str = u64tos(z: u64);

// Converts a uintptr to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn uptrtos(uptr: uintptr) const str = u64tos(uptr: u64);

@test fn utos() void = {
	const samples: [_]u64 = [
		1234,
		4321,
		types::U64_MIN,
		types::U64_MAX,
	];
	const expected = [
		"1234",
		"4321",
		"0",
		"18446744073709551615",
	];

	for (let i = 0z; i < len(samples); i += 1) {
		const s = u64tos(samples[i]);
		assert(s == expected[i]);
	};
};
