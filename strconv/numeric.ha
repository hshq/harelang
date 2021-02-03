use types;

// Converts any [types::signed] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result.
export fn signedtos(n: types::signed) const str = {
	return match (n) {
		i: int => itos(i),
		i: i8  => i8tos(i),
		i: i16 => i16tos(i),
		i: i32 => i32tos(i),
		i: i64 => i64tos(i),
	};
};

// Converts any [types::unsigned] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result.
export fn unsignedtos(n: types::unsigned) const str = {
	return match (n) {
		u: size    => ztos(u),
		u: uint    => utos(u),
		u: u8      => u8tos(u),
		u: u16     => u16tos(u),
		u: u32     => u32tos(u),
		u: u64     => u64tos(u),
	};
};

// Converts any [types::integer] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result.
export fn integertos(n: types::integer) const str = {
	return match (n) {
		s: types::signed   => signedtos(s),
		u: types::unsigned => unsignedtos(u),
	};
};

// Converts any [types::floating] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result.
export fn floatingtos(n: types::floating) const str = {
	abort(); // TODO
};

// Converts any [types::numeric] to a string in base 10. The return value is
// statically allocated and will be overwritten on subsequent calls; see
// [strings::dup] to duplicate the result.
export fn numerictos(n: types::numeric) const str = {
	return match (n) {
		i: types::integer  => integertos(i),
		f: types::floating => floatingtos(f),
	};
};
