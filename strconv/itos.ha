use bytes;
use types;

// Converts an i64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result.
export fn i64tos(i: i64) const str = {
	static assert(types::I64_MAX == 9223372036854775807i64);
	static let buf: [22]u8 = [0u8...]; // 20 chars plus NUL and -
	buf = [0u8...];

	let s = struct {
		b: *[*]u8 = &buf,
		l: size = 0z,
		c: size = 0z,
	};

	const isneg = i < 0i64;
	if (isneg) {
		s.b[s.l] = '-': u32: u8;
		s.l += 1z;
		i = -i;
	} else if (i == 0i64) {
		s.b[s.l] = '0': u32: u8;
		s.l += 1z;
	};

	for (i > 0i64) {
		s.b[s.l] = '0': u32: u8 + (i % 10i64): u8;
		s.l += 1z;
		i /= 10i64;
	};

	const x: size = if (isneg) 1z else 0z;
	bytes::reverse(s.b[x..s.l]);

	s.b[s.l] = 0u8;
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
