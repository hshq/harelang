// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;
use types;

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addi8(a: i8, b: i8) i8 = {
	const res = a + b;
	if (a < 0 == b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I8_MAX else types::I8_MIN;
	};
	return res;
};

@test fn sat_addi8() void = {
	assert(sat_addi8(100, 20) == 120);
	assert(sat_addi8(100, 50) == types::I8_MAX);
	assert(sat_addi8(-100, -50) == types::I8_MIN);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addi16(a: i16, b: i16) i16 = {
	const res = a + b;
	if (a < 0 == b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I16_MAX else types::I16_MIN;
	};
	return res;
};

@test fn sat_addi16() void = {
	assert(sat_addi16(32700, 60) == 32760);
	assert(sat_addi16(32700, 100) == types::I16_MAX);
	assert(sat_addi16(-32700, -100) == types::I16_MIN);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addi32(a: i32, b: i32) i32 = {
	const res = a + b;
	if (a < 0 == b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I32_MAX else types::I32_MIN;
	};
	return res;
};

@test fn sat_addi32() void = {
	assert(sat_addi32(2147483600, 40) == 2147483640);
	assert(sat_addi32(2147483600, 100) == types::I32_MAX);
	assert(sat_addi32(-2147483600, -100) == types::I32_MIN);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addi64(a: i64, b: i64) i64 = {
	const res = a + b;
	if (a < 0 == b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I64_MAX else types::I64_MIN;
	};
	return res;
};

@test fn sat_addi64() void = {
	assert(sat_addi64(9223372036854775800, 5) == 9223372036854775805);
	assert(sat_addi64(9223372036854775800, 10) == types::I64_MAX);
	assert(sat_addi64(-9223372036854775800, -10) == types::I64_MIN);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addu8(a: u8, b: u8) u8 = {
	return if (a + b < a) types::U8_MAX else a + b;
};

@test fn sat_addu8() void = {
	assert(sat_addu8(200, 50) == 250);
	assert(sat_addu8(200, 100) == types::U8_MAX);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addu16(a: u16, b: u16) u16 = {
	return if (a + b < a) types::U16_MAX else a + b;
};

@test fn sat_addu16() void = {
	assert(sat_addu16(65500, 30) == 65530);
	assert(sat_addu16(65500, 50) == types::U16_MAX);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addu32(a: u32, b: u32) u32 = {
	return if (a + b < a) types::U32_MAX else a + b;
};

@test fn sat_addu32() void = {
	assert(sat_addu32(4294967200, 90) == 4294967290);
	assert(sat_addu32(4294967200, 100) == types::U32_MAX);
};

// Computes the saturating addition of 'a' and 'b'.
export fn sat_addu64(a: u64, b: u64) u64 = {
	return if (a + b < a) types::U64_MAX else a + b;
};

@test fn sat_addu64() void = {
	assert(sat_addu64(18446744073709551600, 10) == 18446744073709551610);
	assert(sat_addu64(18446744073709551600, 50) == types::U64_MAX);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subi8(a: i8, b: i8) i8 = {
	const res = a - b;
	if (a < 0 != b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I8_MAX else types::I8_MIN;
	};
	return res;
};

@test fn sat_subi8() void = {
	assert(sat_subi8(-100, 20) == -120);
	assert(sat_subi8(-100, 50) == types::I8_MIN);
	assert(sat_subi8(100, -50) == types::I8_MAX);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subi16(a: i16, b: i16) i16 = {
	const res = a - b;
	if (a < 0 != b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I16_MAX else types::I16_MIN;
	};
	return res;
};

@test fn sat_subi16() void = {
	assert(sat_subi16(-32700, 60) == -32760);
	assert(sat_subi16(-32700, 100) == types::I16_MIN);
	assert(sat_subi16(32700, -100) == types::I16_MAX);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subi32(a: i32, b: i32) i32 = {
	const res = a - b;
	if (a < 0 != b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I32_MAX else types::I32_MIN;
	};
	return res;
};

@test fn sat_subi32() void = {
	assert(sat_subi32(-2147483600, 40) == -2147483640);
	assert(sat_subi32(-2147483600, 100) == types::I32_MIN);
	assert(sat_subi32(2147483600, -100) == types::I32_MAX);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subi64(a: i64, b: i64) i64 = {
	const res = a - b;
	if (a < 0 != b < 0 && a < 0 != res < 0) {
		return if (res < 0) types::I64_MAX else types::I64_MIN;
	};
	return res;
};

@test fn sat_subi64() void = {
	assert(sat_subi64(-9223372036854775800, 5) == -9223372036854775805);
	assert(sat_subi64(-9223372036854775800, 10) == types::I64_MIN);
	assert(sat_subi64(9223372036854775800, -10) == types::I64_MAX);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subu8(a: u8, b: u8) u8 = {
	return if (a - b > a) types::U8_MIN else a - b;
};

@test fn sat_subu8() void = {
	assert(sat_subu8(250, 50) == 200);
	assert(sat_subu8(44, 100) == types::U8_MIN);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subu16(a: u16, b: u16) u16 = {
	return if (a - b > a) types::U16_MIN else a - b;
};

@test fn sat_subu16() void = {
	assert(sat_subu16(65530, 30) == 65500);
	assert(sat_subu16(14, 50) == types::U16_MIN);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subu32(a: u32, b: u32) u32 = {
	return if (a - b > a) types::U32_MIN else a - b;
};

@test fn sat_subu32() void = {
	assert(sat_subu32(4294967290, 90) == 4294967200);
	assert(sat_subu32(4, 100) == types::U32_MIN);
};

// Computes the saturating subtraction of 'b' from 'a'.
export fn sat_subu64(a: u64, b: u64) u64 = {
	return if (a - b > a) types::U64_MIN else a - b;
};

@test fn sat_subu64() void = {
	assert(sat_subu64(18446744073709551610, 10) == 18446744073709551600);
	assert(sat_subu64(44, 50) == types::U64_MIN);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_muli8(a: i8, b: i8) i8 = {
	const fullres = a: int * b: int;
	const res = fullres: i8;
	if (res != fullres) {
		return if (res < 0) types::I8_MAX else types::I8_MIN;
	};
	return res;
};

@test fn sat_muli8() void = {
	assert(sat_muli8(11, 11) == 121);
	assert(sat_muli8(12, 12) == types::I8_MAX);
	assert(sat_muli8(12, -12) == types::I8_MIN);
	assert(sat_muli8(-12, 12) == types::I8_MIN);
	assert(sat_muli8(-12, -12) == types::I8_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_muli16(a: i16, b: i16) i16 = {
	const fullres = a: int * b: int;
	const res = fullres: i16;
	if (res != fullres) {
		return if (res < 0) types::I16_MAX else types::I16_MIN;
	};
	return res;
};

@test fn sat_muli16() void = {
	assert(sat_muli16(181, 181) == 32761);
	assert(sat_muli16(182, 182) == types::I16_MAX);
	assert(sat_muli16(182, -182) == types::I16_MIN);
	assert(sat_muli16(-182, 182) == types::I16_MIN);
	assert(sat_muli16(-182, -182) == types::I16_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_muli32(a: i32, b: i32) i32 = {
	const fullres = a: i64 * b: i64;
	const res = fullres: i32;
	if (res != fullres) {
		return if (res < 0) types::I32_MAX else types::I32_MIN;
	};
	return res;
};

@test fn sat_muli32() void = {
	assert(sat_muli32(46340, 46340) == 2147395600);
	assert(sat_muli32(46341, 46341) == types::I32_MAX);
	assert(sat_muli32(46341, -46341) == types::I32_MIN);
	assert(sat_muli32(-46341, 46341) == types::I32_MIN);
	assert(sat_muli32(-46341, -46341) == types::I32_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_muli64(a: i64, b: i64) i64 = {
	const (hi, lo) = math::mulu64(math::absi64(a), math::absi64(b));
	if (hi != 0 || lo & (1 << 63) != 0) {
		return if (a < 0 == b < 0) types::I64_MAX else types::I64_MIN;
	};
	return a * b;
};

@test fn sat_muli64() void = {
	assert(sat_muli64(3037000499, 3037000499) == 9223372030926249001);
	assert(sat_muli64(3037000500, 3037000500) == types::I64_MAX);
	assert(sat_muli64(3037000500, -3037000500) == types::I64_MIN);
	assert(sat_muli64(-3037000500, 3037000500) == types::I64_MIN);
	assert(sat_muli64(-3037000500, -3037000500) == types::I64_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_mulu8(a: u8, b: u8) u8 = {
	const res = a: uint * b: uint;
	return if (res > types::U8_MAX) types::U8_MAX else res: u8;
};

@test fn sat_mulu8() void = {
	assert(sat_mulu8(15, 15) == 225);
	assert(sat_mulu8(16, 16) == types::U8_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_mulu16(a: u16, b: u16) u16 = {
	const res = a: uint * b: uint;
	return if (res > types::U16_MAX) types::U16_MAX else res: u16;
};

@test fn sat_mulu16() void = {
	assert(sat_mulu16(255, 255) == 65025);
	assert(sat_mulu16(256, 256) == types::U16_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_mulu32(a: u32, b: u32) u32 = {
	const res = a: u64 * b: u64;
	return if (res > types::U32_MAX) types::U32_MAX else res: u32;
};

@test fn sat_mulu32() void = {
	assert(sat_mulu32(65535, 65535) == 4294836225);
	assert(sat_mulu32(65536, 65536) == types::U32_MAX);
};

// Computes the saturating multiplication of 'a' and 'b'.
export fn sat_mulu64(a: u64, b: u64) u64 = {
	const (hi, lo) = math::mulu64(a, b);
	return if (hi != 0) types::U64_MAX else lo;
};

@test fn sat_mulu64() void = {
	assert(sat_mulu64(4294967295, 4294967295) == 18446744065119617025);
	assert(sat_mulu64(4294967296, 4294967296) == types::U64_MAX);
};
