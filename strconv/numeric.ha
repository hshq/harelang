use types;

// Converts any types::signed to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result, or [strconv::itosb] to pass your own
// string buffer.
//
//	let a = strconv::signedtos(123);
//	io::printf("%s", a); // 123
//
//	let a = strconv::signedtos(123);
//	let b = strconv::signedtos(321);
//	io::printf("%s %s", a, b); // 321 321
export fn signedtos(n: types::signed) const str = {
	return match (n) {
		i: int => itos(i),
		i: i8  => i8tos(i),
		i: i16 => i16tos(i),
		i: i32 => i32tos(i),
		i: i64 => i64tos(i),
	};
};

// Converts any types::unsigned to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result, or [strconv::itosb] to pass your own
// string buffer.
//
//	let a = strconv::unsignedtos(123);
//	io::printf("%s", a); // 123
//
//	let a = strconv::unsignedtos(123);
//	let b = strconv::unsignedtos(321);
//	io::printf("%s %s", a, b); // 321 321
export fn unsignedtos(n: (...types::unsigned | uintptr)) const str = {
	return match (n) {
		u: size    => ztos(u),
		u: uint    => utos(u),
		u: uintptr => uptrtos(u),
		u: u8      => u8tos(u),
		u: u16     => u16tos(u),
		u: u32     => u32tos(u),
		u: u64     => u64tos(u),
	};
};
