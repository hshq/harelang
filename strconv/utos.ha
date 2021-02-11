use bytes;
use types;

// Converts a u64 to a string, in the given base. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn u64tosb(u: u64, base: uint) const str = {
	static assert(types::U64_MAX == 18446744073709551615);
	assert(base == 2 || base == 8 || base == 10 || base == 16);

	static const lut: [_]rune = [
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
	];

	static let buf: [21]u8 = [0...]; // 20 digits plus NUL
	buf = [0...];

	let s = types::string { data = &buf, ... };
	if (u == 0) {
		s.data[s.length] = '0': u32: u8;
		s.length += 1z;
	};

	for (u > 0u64) {
		s.data[s.length] = lut[(u % base: u64)]: u32: u8;
		s.length += 1;
		u /= base;
	};

	bytes::reverse(s.data[..s.length]);
	s.data[s.length] = 0;
	return *(&s: *str);
};

// Converts a u32 to a string, in the given base. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn u32tosb(u: u32, base: uint) const str = u64tosb(u: u32, base);

// Converts a u16 to a string, in the given base. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn u16tosb(u: u16, base: uint) const str = u64tosb(u: u16, base);

// Converts a u8 to a string, in the given base. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn u8tosb(u: u8, base: uint) const str = u64tosb(u: u8, base);

// Converts a uint to a string, in the given base. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn utosb(u: uint, base: uint) const str = u64tosb(u: uint, base);

// Converts a size to a string, in the given base. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result. Valid bases are 2, 8, 10 and 16.
export fn ztosb(u: uint, base: uint) const str = u64tosb(u: uint, base);

// Converts a u64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn u64tos(u: u64) const str = u64tosb(u, 10u);

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

@test fn utosb() void = {
	assert("11010" == u64tosb(0b11010, 2));
	assert("1234567" == u64tosb(0o1234567, 8));
	assert("123456789" == u64tosb(123456789, 10));
	assert("123456789ABCDEF" == u64tosb(0x123456789ABCDEF, 16));
};

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
