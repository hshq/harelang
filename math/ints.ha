// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Returns the absolute value of signed integer n.
export fn absi8(n: i8) u8 = if (n < 0) -n: u8 else n: u8;

// Returns the absolute value of signed integer n.
export fn absi16(n: i16) u16 = if (n < 0) -n: u16 else n: u16;

// Returns the absolute value of signed integer n.
export fn absi32(n: i32) u32 = if (n < 0) -n: u32 else n: u32;

// Returns the absolute value of signed integer n.
export fn absi64(n: i64) u64 = if (n < 0) -n: u64 else n: u64;

// Returns the absolute value of signed integer n.
export fn absi(n: int) uint = if (n < 0) -n: uint else n: uint;

@test fn absi() void = {
	assert(absi8(2) == 2);
	assert(absi8(-2) == 2);
	assert(absi8(types::I8_MIN) == types::I8_MIN: u8);
	assert(absi16(2) == 2);
	assert(absi16(-2) == 2);
	assert(absi16(types::I16_MIN) == types::I16_MIN: u16);
	assert(absi32(2) == 2);
	assert(absi32(-2) == 2);
	assert(absi32(types::I32_MIN) == types::I32_MIN: u32);
	assert(absi64(2) == 2);
	assert(absi64(-2) == 2);
	assert(absi64(types::I64_MIN) == types::I64_MIN: u64);
	assert(absi(2) == 2);
	assert(absi(-2) == 2);
	assert(absi(types::INT_MIN) == types::INT_MIN: uint);
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi8(n: i8) i8 = {
	if (n > 0i8) {
		return 1i8;
	};
	if (n < 0i8) {
		return -1i8;
	};
	return 0i8;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi16(n: i16) i16 = {
	if (n > 0i16) {
		return 1i16;
	};
	if (n < 0i16) {
		return -1i16;
	};
	return 0i16;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi32(n: i32) i32 = {
	if (n > 0i32) {
		return 1i32;
	};
	if (n < 0i32) {
		return -1i32;
	};
	return 0i32;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi64(n: i64) i64 = {
	if (n > 0i64) {
		return 1i64;
	};
	if (n < 0i64) {
		return -1i64;
	};
	return 0i64;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi(n: int) i64 = {
	if (n > 0) {
		return 1;
	};
	if (n < 0) {
		return -1;
	};
	return 0;
};

@test fn signi() void = {
	assert(signi8(2i8) == 1i8);
	assert(signi8(-2i8) == -1i8);
	assert(signi8(0i8) == 0i8);
	assert(signi16(2i16) == 1i16);
	assert(signi16(-2i16) == -1i16);
	assert(signi16(0i16) == 0i16);
	assert(signi32(2i32) == 1i32);
	assert(signi32(-2i32) == -1i32);
	assert(signi32(0i32) == 0i32);
	assert(signi64(2i64) == 1i64);
	assert(signi64(-2i64) == -1i64);
	assert(signi64(0i64) == 0i64);
	assert(signi(2) == 1);
	assert(signi(-2) == -1);
	assert(signi(0) == 0);
};
