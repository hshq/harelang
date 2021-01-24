use bytes;
use types;

// Converts a u64 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::u64tos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::u64tos(1234u);
//	let b = strconv::u64tos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
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
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::u64tos(123u);
//	io::printf("%s", a); // 123
//
//	let a = strconv::u64tos(123u);
//	let b = strconv::u64tos(321u);
//	io::printf("%s %s", a, b); // 321 321
export fn u8tos(u: u8) const str = u64tos(u: u64);

// Converts a u16 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::u16tos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::u16tos(1234u);
//	let b = strconv::u16tos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
export fn u16tos(u: u16) const str = u64tos(u: u64);

// Converts a u32 to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::u32tos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::u32tos(1234u);
//	let b = strconv::u32tos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
export fn u32tos(u: u32) const str = u64tos(u: u64);

// Converts a uint to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::utos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::utos(1234u);
//	let b = strconv::utos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
export fn utos(u: uint) const str = u64tos(u: u64);

// Converts a size to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::ztos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::ztos(1234u);
//	let b = strconv::ztos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
export fn ztos(z: size) const str = u64tos(z: u64);

// Converts a uintptr to a string, in base 10. The return value is statically
// allocated and will be overwritten on subsequent calls; see [strings::dup] to
// duplicate the result, or [strconv::itosb] to pass your own string buffer.
//
//	let a = strconv::uptrtos(1234u);
//	io::printf("%s", a); // 1234
//
//	let a = strconv::uptrtos(1234u);
//	let b = strconv::uptrtos(4321u);
//	io::printf("%s %s", a, b); // 4321 4321
export fn uptrtos(uptr: uintptr) const str = u64tos(uptr: u64);
