// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// [[sort::cmpfunc]] for use with int.
export fn ints(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *int), b = *(b: const *int);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with uint.
export fn uints(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *uint), b = *(b: const *uint);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with i8.
export fn i8s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *i8): int, b = *(b: const *i8): int;
	return a - b;
};

// [[sort::cmpfunc]] for use with u8.
export fn u8s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *u8): int, b = *(b: const *u8): int;
	return a - b;
};

// [[sort::cmpfunc]] for use with i16.
export fn i16s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *i16): int, b = *(b: const *i16): int;
	return a - b;
};

// [[sort::cmpfunc]] for use with u16.
export fn u16s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *u16): int, b = *(b: const *u16): int;
	return a - b;
};

// [[sort::cmpfunc]] for use with i32.
export fn i32s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *i32), b = *(b: const *i32);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with u32.
export fn u32s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *u32), b = *(b: const *u32);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with i64.
export fn i64s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *i64), b = *(b: const *i64);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with u64.
export fn u64s(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *u64), b = *(b: const *u64);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with size.
export fn sizes(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *size), b = *(b: const *size);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};

// [[sort::cmpfunc]] for use with str. Sorting is done with respect to Unicode
// codepoints; see [[strings::compare]].
export fn strs(a: const *opaque, b: const *opaque) int = {
	// Manual strings::toutf8() to avoid dependency on strings
	const a = *(a: *[]u8), b = *(b: *[]u8);

	let ln = if (len(a) < len(b)) (len(a), -1) else (len(b), 1);
	for (let i = 0z; i < ln.0; i += 1) {
		if (a[i] != b[i]) {
			return a[i]: int - b[i]: int;
		};
	};
	return if (len(a) == len(b)) 0 else ln.1;
};
