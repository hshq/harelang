// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addi8(a: i8, b: i8) (i8, bool) = {
	const res = a + b;
	const overflow = a < 0 == b < 0 && a < 0 != res < 0;
	return (res, overflow);
};

@test fn addi8() void = {
	const (res, overflow) = addi8(100, 20);
	assert(res == 120);
	assert(!overflow);
	const (res, overflow) = addi8(100, 50);
	assert(res == -106);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addi16(a: i16, b: i16) (i16, bool) = {
	const res = a + b;
	const overflow = a < 0 == b < 0 && a < 0 != res < 0;
	return (res, overflow);
};

@test fn addi16() void = {
	const (res, overflow) = addi16(32700, 60);
	assert(res == 32760);
	assert(!overflow);
	const (res, overflow) = addi16(32700, 100);
	assert(res == -32736);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addi32(a: i32, b: i32) (i32, bool) = {
	const res = a + b;
	const overflow = a < 0 == b < 0 && a < 0 != res < 0;
	return (res, overflow);
};

@test fn addi32() void = {
	const (res, overflow) = addi32(2147483600, 40);
	assert(res == 2147483640);
	assert(!overflow);
	const (res, overflow) = addi32(2147483600, 100);
	assert(res == -2147483596);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addi64(a: i64, b: i64) (i64, bool) = {
	const res = a + b;
	const overflow = a < 0 == b < 0 && a < 0 != res < 0;
	return (res, overflow);
};

@test fn addi64() void = {
	const (res, overflow) = addi64(9223372036854775800, 5);
	assert(res == 9223372036854775805);
	assert(!overflow);
	const (res, overflow) = addi64(9223372036854775800, 10);
	assert(res == -9223372036854775806);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addu8(a: u8, b: u8) (u8, bool) = {
	const res = a + b;
	const overflow = res < a;
	return (res, overflow);
};

@test fn addu8() void = {
	const (res, overflow) = addu8(200, 50);
	assert(res == 250);
	assert(!overflow);
	const (res, overflow) = addu8(200, 100);
	assert(res == 44);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addu16(a: u16, b: u16) (u16, bool) = {
	const res = a + b;
	const overflow = res < a;
	return (res, overflow);
};

@test fn addu16() void = {
	const (res, overflow) = addu16(65500, 30);
	assert(res == 65530);
	assert(!overflow);
	const (res, overflow) = addu16(65500, 50);
	assert(res == 14);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addu32(a: u32, b: u32) (u32, bool) = {
	const res = a + b;
	const overflow = res < a;
	return (res, overflow);
};

@test fn addu32() void = {
	const (res, overflow) = addu32(4294967200, 90);
	assert(res == 4294967290);
	assert(!overflow);
	const (res, overflow) = addu32(4294967200, 100);
	assert(res == 4);
	assert(overflow);
};

// Adds 'a' and 'b', returning the result and whether overflow occurred.
export fn addu64(a: u64, b: u64) (u64, bool) = {
	const res = a + b;
	const overflow = res < a;
	return (res, overflow);
};

@test fn addu64() void = {
	const (res, overflow) = addu64(18446744073709551600, 10);
	assert(res == 18446744073709551610);
	assert(!overflow);
	const (res, overflow) = addu64(18446744073709551610, 50);
	assert(res == 44);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subi8(a: i8, b: i8) (i8, bool) = addi8(a, -b);

@test fn subi8() void = {
	const (res, overflow) = subi8(-100, 20);
	assert(res == -120);
	assert(!overflow);
	const (res, overflow) = subi8(-100, 50);
	assert(res == 106);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subi16(a: i16, b: i16) (i16, bool) = addi16(a, -b);

@test fn subi16() void = {
	const (res, overflow) = subi16(-32700, 60);
	assert(res == -32760);
	assert(!overflow);
	const (res, overflow) = subi16(-32700, 100);
	assert(res == 32736);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subi32(a: i32, b: i32) (i32, bool) = addi32(a, -b);

@test fn subi32() void = {
	const (res, overflow) = subi32(-2147483600, 40);
	assert(res == -2147483640);
	assert(!overflow);
	const (res, overflow) = subi32(-2147483600, 100);
	assert(res == 2147483596);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subi64(a: i64, b: i64) (i64, bool) = addi64(a, -b);

@test fn subi64() void = {
	const (res, overflow) = subi64(-9223372036854775800, 5);
	assert(res == -9223372036854775805);
	assert(!overflow);
	const (res, overflow) = subi64(-9223372036854775800, 10);
	assert(res == 9223372036854775806);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subu8(a: u8, b: u8) (u8, bool) = {
	const res = a - b;
	const overflow = res > a;
	return (res, overflow);
};

@test fn subu8() void = {
	const (res, overflow) = subu8(250, 50);
	assert(res == 200);
	assert(!overflow);
	const (res, overflow) = subu8(44, 100);
	assert(res == 200);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subu16(a: u16, b: u16) (u16, bool) = {
	const res = a - b;
	const overflow = res > a;
	return (res, overflow);
};

@test fn subu16() void = {
	const (res, overflow) = subu16(65530, 30);
	assert(res == 65500);
	assert(!overflow);
	const (res, overflow) = subu16(14, 50);
	assert(res == 65500);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subu32(a: u32, b: u32) (u32, bool) = {
	const res = a - b;
	const overflow = res > a;
	return (res, overflow);
};

@test fn subu32() void = {
	const (res, overflow) = subu32(4294967290, 90);
	assert(res == 4294967200);
	assert(!overflow);
	const (res, overflow) = subu32(4, 100);
	assert(res == 4294967200);
	assert(overflow);
};

// Subtracts 'b' from 'a', returning the result and whether overflow occurred.
export fn subu64(a: u64, b: u64) (u64, bool) = {
	const res = a - b;
	const overflow = res > a;
	return (res, overflow);
};

@test fn subu64() void = {
	const (res, overflow) = subu64(18446744073709551610, 10);
	assert(res == 18446744073709551600);
	assert(!overflow);
	const (res, overflow) = subu64(44, 50);
	assert(res == 18446744073709551610);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn muli8(a: i8, b: i8) (i8, bool) = {
	const fullres = a: i16 * b: i16;
	const res = fullres: i8;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn muli8() void = {
	const (res, overflow) = muli8(11, 11);
	assert(res == 121);
	assert(!overflow);
	const (res, overflow) = muli8(12, 12);
	assert(res == -112);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn muli16(a: i16, b: i16) (i16, bool) = {
	const fullres = a: i32 * b: i32;
	const res = fullres: i16;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn muli16() void = {
	const (res, overflow) = muli16(181, 181);
	assert(res == 32761);
	assert(!overflow);
	const (res, overflow) = muli16(182, 182);
	assert(res == -32412);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn muli32(a: i32, b: i32) (i32, bool) = {
	const fullres = a: i64 * b: i64;
	const res = fullres: i32;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn muli32() void = {
	const (res, overflow) = muli32(46340, 46340);
	assert(res == 2147395600);
	assert(!overflow);
	const (res, overflow) = muli32(46341, 46341);
	assert(res == -2147479015);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn muli64(a: i64, b: i64) (i64, bool) = {
	const (hi, lo) = math::mulu64(math::absi64(a), math::absi64(b));
	const res = a * b;
	const overflow = hi != 0 || lo & (1 << 63) != 0;
	return (res, overflow);
};

@test fn muli64() void = {
	const (res, overflow) = muli64(3037000499, 3037000499);
	assert(res == 9223372030926249001);
	assert(!overflow);
	const (res, overflow) = muli64(3037000500, 3037000500);
	assert(res == -9223372036709301616);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn mulu8(a: u8, b: u8) (u8, bool) = {
	const fullres = a: u16 * b: u16;
	const res = fullres: u8;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn mulu8() void = {
	const (res, overflow) = mulu8(15, 15);
	assert(res == 225);
	assert(!overflow);
	const (res, overflow) = mulu8(16, 16);
	assert(res == 0);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn mulu16(a: u16, b: u16) (u16, bool) = {
	const fullres = a: u32 * b: u32;
	const res = fullres: u16;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn mulu16() void = {
	const (res, overflow) = mulu16(255, 255);
	assert(res == 65025);
	assert(!overflow);
	const (res, overflow) = mulu16(256, 256);
	assert(res == 0);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn mulu32(a: u32, b: u32) (u32, bool) = {
	const fullres = a: u64 * b: u64;
	const res = fullres: u32;
	const overflow = res != fullres;
	return (res, overflow);
};

@test fn mulu32() void = {
	const (res, overflow) = mulu32(65535, 65535);
	assert(res == 4294836225);
	assert(!overflow);
	const (res, overflow) = mulu32(65536, 65536);
	assert(res == 0);
	assert(overflow);
};

// Multiplies 'a' and 'b' returning the result and whether overflow occurred.
export fn mulu64(a: u64, b: u64) (u64, bool) = {
	const (hi, lo) = math::mulu64(a, b);
	const res = lo;
	const overflow = hi != 0;
	return (res, overflow);
};

@test fn mulu64() void = {
	const (res, overflow) = mulu64(4294967295, 4294967295);
	assert(res == 18446744065119617025);
	assert(!overflow);
	const (res, overflow) = mulu64(4294967296, 4294967296);
	assert(res == 0);
	assert(overflow);
};
