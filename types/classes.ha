// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// A tagged union of all signed integer types.
export type signed = (i8 | i16 | i32 | i64 | int);

// A tagged union of all unsigned integer types, excluding uintptr.
export type unsigned = (u8 | u16 | u32 | u64 | uint | size);

// A tagged union of all integer types.
export type integer = (...signed | ...unsigned);

// A tagged union of all floating point numeric types.
export type floating = (f32 | f64);

// A tagged union of all numeric types.
export type numeric = (...integer | ...floating);

// A type representing the internal structure of strings, useful for low-level
// string manipulation.
export type string = struct {
	// UTF-8 encoded octets.
	data: nullable *[*]u8,

	// The length capacity, in octets of UTF-8 data.
	length: size,

	// The allocated capacity, in octets of UTF-8 data.
	capacity: size,
};

// A type representing the internal structure of slices, useful for low-level
// slice manipulation.
export type slice = struct {
	// The slice contents.
	data: nullable *opaque,

	// The number of members of the slice.
	length: size,

	// The allocated capacity (in members) of data.
	capacity: size,
};
