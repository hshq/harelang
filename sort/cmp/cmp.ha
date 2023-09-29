// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;

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
	const a = a: const *str, b = b: const *str;
	return strings::compare(*a, *b);
};
