use types;
use strings;

// Converts a string to an i64 in base 10. If the string contains any
// non-numeric characters, except '-' at the start, or if it's empty,
// [strconv::invalid] is returned. If the number is too large to be represented
// by an i64, [strconv::overflow] is returned.
export fn stoi64(s: str) (i64 | invalid | overflow) = {
	if (len(s) == 0) return 0: invalid;
	let b = strings::to_utf8(s);
	let sign = 1i64;
	let max = types::I64_MAX: u64;
	if (b[0] == '-': u32: u8) {
		sign = -1;
		max += 1;
	};
	let u = if (sign < 0) stou64(strings::from_utf8_unsafe(b[1..]))
		else stou64(s);
	let n = u?;
	if (n > max) {
		return overflow;
	};
	return n: i64 * sign;
};

// Converts a string to an i32 in base 10. If the string contains any
// non-numeric characters, except '-' at the start, or if it's empty,
// [strconv::invalid] is returned. If the number is too large to be represented
// by an i32, [strconv::overflow] is returned.
export fn stoi32(s: str) (i32 | invalid | overflow) = {
	let n = stoi64(s)?;
	if (n >= types::I32_MIN: i64 && n <= types::I32_MAX: i64) {
		return n: i32;
	};
	return overflow;
};

// Converts a string to an i16 in base 10. If the string contains any
// non-numeric characters, except '-' at the start, or if it's empty,
// [strconv::invalid] is returned. If the number is too large to be represented
// by an i16, [strconv::overflow] is returned.
export fn stoi16(s: str) (i16 | invalid | overflow) = {
	let n = stoi64(s)?;
	if (n >= types::I16_MIN: i64 && n <= types::I16_MAX: i64) {
		return n: i16;
	};
	return overflow;
};

// Converts a string to an i8 in base 10. If the string contains any
// non-numeric characters, except '-' at the start, or if it's empty,
// [strconv::invalid] is returned. If the number is too large to be represented
// by an i8, [strconv::overflow] is returned.
export fn stoi8(s: str) (i8 | invalid | overflow) = {
	let n= stoi64(s)?;
	if (n >= types::I8_MIN: i64 && n <= types::I8_MAX: i64) {
		return n: i8;
	};
	return overflow;
};

// Converts a string to an int in base 10. If the string contains any
// non-numeric characters, except '-' at the start, or if it's empty,
// [strconv::invalid] is returned. If the number is too large to be represented
// by an int, [strconv::overflow] is returned.
export fn stoi(s: str) (int | invalid | overflow) = {
	static assert(size(int) == size(i32) || size(int) == size(i64));
	return
		if (size(int) == size(i32)) stoi32(s)?: int
		else stoi64(s)?: int;
};
