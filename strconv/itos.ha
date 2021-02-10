use bytes;
use types;

// Converts an i64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn i64tos(i: i64) const str = {
	static assert(types::I64_MAX == 9223372036854775807);
	if (i == types::I64_MIN) {
		return "-9223372036854775808";
	};

	static let buf: [22]u8 = [0...]; // 20 chars plus NUL and -
	buf = [0...];

	let s = types::string { data = &buf, ... };

	const isneg = i < 0;
	if (isneg) {
		s.data[s.length] = '-': u32: u8;
		s.length += 1;
		i = -i;
	} else if (i == 0) {
		s.data[s.length] = '0': u32: u8;
		s.length += 1;
	};

	for (i > 0) {
		s.data[s.length] = '0': u32: u8 + (i % 10): u8;
		s.length += 1;
		i /= 10;
	};

	const x: size = if (isneg) 1 else 0;
	bytes::reverse(s.data[x..s.length]);

	s.data[s.length] = 0;
	return *(&s: *str);
};

// Converts an i8 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn i8tos(i: i8) const str = i64tos(i: i64);

// Converts an i16 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn i16tos(i: i16) const str = i64tos(i: i64);

// Converts an i32 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn i32tos(i: i32) const str = i64tos(i: i64);

// Converts an int to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn itos(i: int) const str = i64tos(i: i64);

@test fn itos() void = {
	const samples: [_]i64 = [
		1234,
		4321,
		-1337,
		0,
		types::I64_MAX,
		types::I64_MIN,
	];
	const expected = [
		"1234",
		"4321",
		"-1337",
		"0",
		"9223372036854775807",
		"-9223372036854775808",
	];

	for (let i = 0z; i < len(samples); i += 1) {
		const s = i64tos(samples[i]);
		assert(s == expected[i]);
	};
};
