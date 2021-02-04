use bytes;
use types;

// Converts a u64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u64tos(u: u64) const str = {
	static assert(types::U64_MAX == 18446744073709551615u64);
	static let buf: [21]u8 = [0u8...]; // 20 digits plus NUL
	buf = [0u8...];

	let s = struct {
		b: *[*]u8 = &buf,
		l: size = 0z,
		c: size = 0z,
	};

	if (u == 0u64) {
		s.b[s.l] = '0': u32: u8;
		s.l += 1z;
	};

	for (u > 0u64) {
		s.b[s.l] = '0': u32: u8 + (u % 10u64): u8;
		s.l += 1z;
		u /= 10u64;
	};

	bytes::reverse(s.b[..s.l]);
	s.b[s.l] = 0u8;
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
	// U64_MAX: https://todo.sr.ht/~sircmpwn/hare-v2/185
	const samples = [
		1234u64,
		4321u64,
		types::U64_MIN,
		//types::U64_MAX,
	];
	const expected = [
		"1234",
		"4321",
		"0",
		//"18446744073709551615",
	];

	for (let i = 0z; i < len(samples); i += 1z) {
		const s = u64tos(samples[i]);
		assert(s == expected[i]);
	};
};
