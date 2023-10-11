// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Sections of the code below are based on Go's implementation, in particular
// https://raw.githubusercontent.com/golang/go/master/src/math/bits/bits.go.
//
// The Go copyright notice:
// ====================================================
// Copyright (c) 2009 The Go Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ====================================================

// The number of bits required to represent the first 256 numbers.
const LEN8TAB: [256]u8 = [
	0x00, 0x01, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04,
	0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
	0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x06,
	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
	0x06, 0x06, 0x06, 0x06, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08,
	0x08, 0x08, 0x08, 0x08,
];

const NTZ8TAB: [256]u8 = [
	0x08, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x05, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x06, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x05, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x07, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x05, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x06, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x05, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00,
	0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00,
	0x02, 0x00, 0x01, 0x00,
];

// See http://supertech.csail.mit.edu/papers/debruijn.pdf
def DEBRUIJN32: u32 = 0x077CB531;

const DEBRUIJN32TAB: [32]u8 = [
	0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
	31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9,
];

def DEBRUIJN64: u64 = 0x03f79d71b4ca8b09;

const DEBRUIJN64TAB: [64]u8 = [
	0, 1, 56, 2, 57, 49, 28, 3, 61, 58, 42, 50, 38, 29, 17, 4,
	62, 47, 59, 36, 45, 43, 51, 22, 53, 39, 33, 30, 24, 18, 12, 5,
	63, 55, 48, 27, 60, 41, 37, 16, 46, 35, 44, 21, 52, 32, 23, 11,
	54, 26, 40, 15, 34, 20, 31, 10, 25, 14, 19, 9, 13, 8, 7, 6,
];

// The size of an unsigned int: 32 or 64
def UINT_SIZE: u8 = (size(uint): u8) * 8;

// Returns the minimum number of bits required to represent x.
export fn bit_size_u8(x: u8) u8 = {
	return LEN8TAB[x];
};

// Returns the minimum number of bits required to represent x.
export fn bit_size_u16(x: u16) u8 = {
	let res = 0u8;
	if (x >= 1u16 << 8) {
		x >>= 8;
		res += 8;
	};
	return res + LEN8TAB[x];
};

// Returns the minimum number of bits required to represent x.
export fn bit_size_u32(x: u32) u8 = {
	let res = 0u8;
	if (x >= 1u32 << 16) {
		x >>= 16;
		res += 16;
	};
	if (x >= 1u32 << 8) {
		x >>= 8;
		res += 8;
	};
	return res + LEN8TAB[x];
};

// Returns the minimum number of bits required to represent x.
export fn bit_size_u64(x: u64) u8 = {
	let res = 0u8;
	if (x >= 1u64 << 32) {
		x >>= 32;
		res += 32;
	};
	if (x >= 1u64 << 16) {
		x >>= 16;
		res += 16;
	};
	if (x >= 1u64 << 8) {
		x >>= 8;
		res += 8;
	};
	return res + LEN8TAB[x];
};

// Returns the minimum number of bits required to represent x.
export fn bit_size_u(x: uint) u8 = {
	if (UINT_SIZE == 32) {
		return bit_size_u32(x: u32);
	};
	return bit_size_u64(x: u64);
};

@test fn bit_size_u() void = {
	assert(bit_size_u8(0) == 0);
	assert(bit_size_u8(2) == 2);
	assert(bit_size_u8(5) == 3);
	assert(bit_size_u16(5) == 3);
	assert(bit_size_u32(5) == 3);
	assert(bit_size_u64(5) == 3);
	assert(bit_size_u16(31111) == 15);
	assert(bit_size_u32(536870911) == 29);
	assert(bit_size_u64(8589934591) == 33);
	assert(bit_size_u(0) == 0);
	assert(bit_size_u(1) == 1);
};


// Returns the number of leading zero bits in x
// The result is UINT_SIZE for x == 0.
export fn leading_zeros_u(x: uint) u8 = UINT_SIZE - bit_size_u(x);

// Returns the number of leading zero bits in x
// The result is 8 for x == 0.
export fn leading_zeros_u8(x: u8) u8 = 8 - bit_size_u8(x);

// Returns the number of leading zero bits in x
// The result is 16 for x == 0.
export fn leading_zeros_u16(x: u16) u8 = 16 - bit_size_u16(x);

// Returns the number of leading zero bits in x
// The result is 32 for x == 0.
export fn leading_zeros_u32(x: u32) u8 = 32 - bit_size_u32(x);

// Returns the number of leading zero bits in x
// The result is 64 for x == 0.
export fn leading_zeros_u64(x: u64) u8 = 64 - bit_size_u64(x);

@test fn leading_zeros_u() void = {
	assert(leading_zeros_u(0) == UINT_SIZE);
	assert(leading_zeros_u(1) == UINT_SIZE - 1);
	assert(leading_zeros_u8(0) == 8);
	assert(leading_zeros_u8(1) == 8 - 1);
	assert(leading_zeros_u16(0) == 16);
	assert(leading_zeros_u16(1) == 16 - 1);
	assert(leading_zeros_u32(0) == 32);
	assert(leading_zeros_u32(1) == 32 - 1);
	assert(leading_zeros_u64(0) == 64);
	assert(leading_zeros_u64(1) == 64 - 1);
};

// Returns the number of trailing zero bits in x
// The result is UINT_SIZE for x == 0.
export fn trailing_zeros_u(x: uint) u8 = {
	if (UINT_SIZE == 32) {
		return trailing_zeros_u32(x: u32);
	};
	return trailing_zeros_u64(x: u64);
};

// Returns the number of trailing zero bits in x
// The result is 8 for x == 0.
export fn trailing_zeros_u8(x: u8) u8 = NTZ8TAB[x];

// Returns the number of trailing zero bits in x
// The result is 16 for x == 0.
export fn trailing_zeros_u16(x: u16) u8 = {
	if (x == 0) {
		return 16;
	};
	return DEBRUIJN32TAB[(x & -x): u32 * DEBRUIJN32 >> (32 - 5)];
};

// Returns the number of trailing zero bits in x
// The result is 32 for x == 0.
export fn trailing_zeros_u32(x: u32) u8 = {
	if (x == 0) {
		return 32;
	};
	return DEBRUIJN32TAB[(x & -x) * DEBRUIJN32 >> (32 - 5)];
};

// Returns the number of trailing zero bits in x
// The result is 64 for x == 0.
export fn trailing_zeros_u64(x: u64) u8 = {
	if (x == 0) {
		return 64;
	};
	return DEBRUIJN64TAB[(x & -x) * DEBRUIJN64 >> (64 - 6)];
};

@test fn trailing_zeros_u() void = {
	assert(trailing_zeros_u8(0) == 8);
	for (let x: u8 = 1 << 7, i = 7u8; x > 0; x >>= 1) {
		assert(trailing_zeros_u8(x) == i);
		i -= 1;
	};

	assert(trailing_zeros_u16(0) == 16);
	for (let x: u16 = 1 << 15, i = 15u8; x > 0; x >>= 1) {
		assert(trailing_zeros_u16(x) == i);
		i -= 1;
	};

	assert(trailing_zeros_u32(0) == 32);
	for (let x: u32 = 1 << 31, i = 31u8; x > 0; x >>= 1) {
		assert(trailing_zeros_u32(x) == i);
		i -= 1;
	};

	assert(trailing_zeros_u64(0) == 64);
	for (let x: u64 = 1 << 63, i = 63u8; x > 0; x >>= 1) {
		assert(trailing_zeros_u64(x) == i);
		i -= 1;
	};

	assert(trailing_zeros_u(0) == UINT_SIZE);
	assert(trailing_zeros_u(1) == 0);
};

// Returns the number of bits set (the population count) of x.
export fn popcount(x: u64) u8 = {
	let i = 0u8;
	for (x != 0; x >>= 1) {
		if (x & 1 == 1) {
			i += 1;
		};
	};
	return i;
};

@test fn popcount() void = {
	assert(popcount(0) == 0);
	assert(popcount(0b11010110) == 5);
	assert(popcount(~0) == 64);
};

// Returns the sum with carry of x, y and carry: sum = x + y + carry.
// The carry input must be 0 or 1, otherwise the behavior is undefined.
// The carry_out output is guaranteed to be 0 or 1.
export fn addu32(x: u32, y: u32, carry: u32) (u32, u32) = {
	const sum64 = (x: u64) + (y: u64) + (carry: u64);
	const sum = (sum64: u32);
	const carry_out = ((sum64 >> 32): u32);
	return (sum, carry_out);
};

// Returns the sum with carry of x, y and carry: sum = x + y + carry.
// The carry input must be 0 or 1, otherwise the behavior is undefined.
// The carry_out output is guaranteed to be 0 or 1.
export fn addu64(x: u64, y: u64, carry: u64) (u64, u64) = {
	const sum = x + y + carry;
	// The sum will overflow if both top bits are set (x & y) or if one of
	// them is (x | y), and a carry from the lower place happened. If such a
	// carry happens, the top bit will be 1 + 0 + 1 = 0 (& ~sum).
	const carry_out = ((x & y) | ((x | y) & ~sum)) >> 63;
	return (sum, carry_out);
};

// Calls either addu32() or addu64() depending on size(uint).
export fn addu(x: uint, y: uint, carry: uint) (uint, uint) = {
	if (UINT_SIZE == 32) {
		const res = addu32((x: u32), (y: u32), (carry: u32));
		return ((res.0: uint), (res.1: uint));
	};
	const res = addu64((x: u64), (y: u64), (carry: u64));
	return ((res.0: uint), (res.1: uint));
};

@test fn addu() void = {
	// 32
	let res = addu32(2u32, 2u32, 0u32);
	assert(res.0 == 4u32);
	assert(res.1 == 0u32);
	let res = addu32(2u32, 2u32, 1u32);
	assert(res.0 == 5u32);
	assert(res.1 == 0u32);
	let res = addu32(~0u32, 0u32, 0u32);
	assert(res.0 == ~0u32);
	assert(res.1 == 0u32);
	let res = addu32(~0u32, 1u32, 0u32);
	assert(res.0 == 0u32);
	assert(res.1 == 1u32);

	// 64
	let res = addu64(2u64, 2u64, 0u64);
	assert(res.0 == 4u64);
	assert(res.1 == 0u64);
	let res = addu64(2u64, 2u64, 1u64);
	assert(res.0 == 5u64);
	assert(res.1 == 0u64);
	let res = addu64(~0u64, 0u64, 0u64);
	assert(res.0 == ~0u64);
	assert(res.1 == 0u64);
	let res = addu64(~0u64, 1u64, 0u64);
	assert(res.0 == 0u64);
	assert(res.1 == 1u64);

	// addu()
	let res = addu(2u, 2u, 0u);
	assert(res.0 == 4u);
	assert(res.1 == 0u);
	let res = addu(2u, 2u, 1u);
	assert(res.0 == 5u);
	assert(res.1 == 0u);
};

// Returns the difference of x, y and borrow, diff = x - y - borrow.
// The borrow input must be 0 or 1, otherwise the behavior is undefined.
// The borrow_out output is guaranteed to be 0 or 1.
export fn subu32(x: u32, y: u32, borrow: u32) (u32, u32) = {
	const diff = x - y - borrow;
	// The difference will underflow if the top bit of x is not set and the
	// top bit of y is set (^x & y) or if they are the same (^(x ^ y)) and a
	// borrow from the lower place happens. If that borrow happens, the
	// result will be 1 - 1 - 1 = 0 - 0 - 1 = 1 (& diff).
	const borrow_out = ((~x & y) | (~(x ^ y) & diff)) >> 31;
	return (diff, borrow_out);
};

// Returns the difference of x, y and borrow, diff = x - y - borrow.
// The borrow input must be 0 or 1, otherwise the behavior is undefined.
// The borrow_out output is guaranteed to be 0 or 1.
export fn subu64(x: u64, y: u64, borrow: u64) (u64, u64) = {
	const diff = x - y - borrow;
	// See subu32 for the bit logic.
	const borrow_out = ((~x & y) | (~(x ^ y) & diff)) >> 63;
	return (diff, borrow_out);
};

// Calls either mulu32() or mulu64() depending on size(uint).
export fn subu(x: uint, y: uint, carry: uint) (uint, uint) = {
	if (UINT_SIZE == 32) {
		const res = subu32((x: u32), (y: u32), (carry: u32));
		return ((res.0: uint), (res.1: uint));
	};
	const res = subu64((x: u64), (y: u64), (carry: u64));
	return ((res.0: uint), (res.1: uint));
};

@test fn subu() void = {
	// 32
	let res = subu32(4u32, 2u32, 0u32);
	assert(res.0 == 2u32);
	assert(res.1 == 0u32);
	let res = subu32(4u32, 2u32, 1u32);
	assert(res.0 == 1u32);
	assert(res.1 == 0u32);
	let res = subu32(0u32, 0u32, 0u32);
	assert(res.0 == 0u32);
	assert(res.1 == 0u32);
	let res = subu32(0u32, 1u32, 0u32);
	assert(res.0 == ~0u32);
	assert(res.1 == 1u32);

	// 64
	let res = subu64(4u64, 2u64, 0u64);
	assert(res.0 == 2u64);
	assert(res.1 == 0u64);
	let res = subu64(4u64, 2u64, 1u64);
	assert(res.0 == 1u64);
	assert(res.1 == 0u64);
	let res = subu64(0u64, 0u64, 0u64);
	assert(res.0 == 0u64);
	assert(res.1 == 0u64);
	let res = subu64(0u64, 1u64, 0u64);
	assert(res.0 == ~0u64);
	assert(res.1 == 1u64);

	// subu()
	let res = subu(4u, 2u, 0u);
	assert(res.0 == 2u);
	assert(res.1 == 0u);
	let res = subu(4u, 2u, 1u);
	assert(res.0 == 1u);
	assert(res.1 == 0u);
};

// Returns the 64-bit product of x and y: (hi, lo) = x * y
// with the product bits' upper half returned in hi and the lower
// half returned in lo.
export fn mulu32(x: u32, y: u32) (u32, u32) = {
	const product = (x: u64) * (y: u64);
	const hi = ((product >> 32): u32);
	const lo = (product: u32);
	return (hi, lo);
};

// Returns the 128-bit product of x and y: (hi, lo) = x * y
// with the product bits' upper half returned in hi and the lower
// half returned in lo.
export fn mulu64(x: u64, y: u64) (u64, u64) = {
	const mask32 = (1u64 << 32) - 1;
	const x0 = x & mask32;
	const x1 = x >> 32;
	const y0 = y & mask32;
	const y1 = y >> 32;
	const w0 = x0 * y0;
	const t = (x1 * y0) + (w0 >> 32);
	let w1 = t & mask32;
	const w2 = t >> 32;
	w1 += x0 * y1;
	const hi = (x1 * y1) + w2 + (w1 >> 32);
	const lo = x * y;
	return (hi, lo);
};

// Calls either mulu32() or mulu64() depending on size(uint).
export fn mulu(x: uint, y: uint) (uint, uint) = {
	if (UINT_SIZE == 32) {
		const res = mulu32((x: u32), (y: u32));
		return ((res.0: uint), (res.1: uint));
	};
	const res = mulu64((x: u64), (y: u64));
	return ((res.0: uint), (res.1: uint));
};

@test fn mulu() void = {
	// 32
	let res = mulu32(2u32, 3u32);
	assert(res.0 == 0u32);
	assert(res.1 == 6u32);
	let res = mulu32(~0u32, 2u32);
	assert(res.0 == 1u32);
	assert(res.1 == ~0u32 - 1);

	// 64
	let res = mulu64(2u64, 3u64);
	assert(res.0 == 0u64);
	assert(res.1 == 6u64);
	let res = mulu64(~0u64, 2u64);
	assert(res.0 == 1u64);
	assert(res.1 == ~0u64 - 1);

	// mulu()
	let res = mulu(2u, 3u);
	assert(res.0 == 0u);
	assert(res.1 == 6u);
	let res = mulu(~0u, 2u);
	assert(res.0 == 1u);
	assert(res.1 == ~0u - 1);
};

// Returns the quotient and remainder of (hi, lo) divided by y:
// quo = (hi, lo) / y, rem = (hi, lo) % y with the dividend bits' upper
// half in parameter hi and the lower half in parameter lo.
// Panics for y == 0 (division by zero) or y <= hi (quotient overflow).
export fn divu32(hi: u32, lo: u32, y: u32) (u32, u32) = {
	assert(y != 0);
	assert(y > hi);
	const z = (hi: u64) << 32 | (lo: u64);
	const quo = ((z / (y: u64)): u32);
	const rem = ((z % (y: u64)): u32);
	return (quo, rem);
};

// Returns the quotient and remainder of (hi, lo) divided by y:
// quo = (hi, lo) / y, rem = (hi, lo) % y with the dividend bits' upper
// half in parameter hi and the lower half in parameter lo.
// Panics for y == 0 (division by zero) or y <= hi (quotient overflow).
export fn divu64(hi: u64, lo: u64, y: u64) (u64, u64) = {
	const two32 = 1u64 << 32;
	const mask32 = two32 - 1;
	assert(y != 0);
	assert(y > hi);

	const s = leading_zeros_u64(y);
	y <<= s;

	const yn1 = y >> 32;
	const yn0 = y & mask32;
	const un32 = (hi << s) | (lo >> (64 - s));
	const un10 = lo << s;
	const un1 = un10 >> 32;
	const un0 = un10 & mask32;
	let q1 = un32 / yn1;
	let rhat = un32 - (q1 * yn1);

	for (q1 >= two32 || (q1 * yn0) > ((two32 * rhat) + un1)) {
		q1 -= 1;
		rhat += yn1;
		if (rhat >= two32) {
			break;
		};
	};

	const un21 = (un32 * two32) + un1 - (q1 * y);
	let q0 = un21 / yn1;
	rhat = un21 - (q0 * yn1);

	for (q0 >= two32 || (q0 * yn0) > ((two32 * rhat) + un0)) {
		q0 -= 1;
		rhat += yn1;
		if (rhat >= two32) {
			break;
		};
	};

	const quo = (q1 * two32) + q0;
	const rem = ((un21 * two32) + un0 - (q0 * y)) >> s;
	return (quo, rem);
};

// Calls either divu32() or divu64() depending on size(uint).
export fn divu(hi: uint, lo: uint, y: uint) (uint, uint) = {
	if (UINT_SIZE == 32) {
		const res = divu32((hi: u32), (lo: u32), (y: u32));
		return ((res.0: uint), (res.1: uint));
	};
	const res = divu64((hi: u64), (lo: u64), (y: u64));
	return ((res.0: uint), (res.1: uint));
};

@test fn divu() void = {
	// 32
	let res = divu32(0u32, 4u32, 2u32);
	assert(res.0 == 2u32);
	assert(res.1 == 0u32);
	let res = divu32(0u32, 5u32, 2u32);
	assert(res.0 == 2u32);
	assert(res.1 == 1u32);
	let res = divu32(1u32, 0u32, 2u32);
	assert(res.0 == (1u32 << 31));
	assert(res.1 == 0u32);
	// These should panic.
	// let res = divu32(1u32, 1u32, 0u32);
	// let res = divu32(1u32, 0u32, 1u32);

	// 64
	let res = divu64(0u64, 4u64, 2u64);
	assert(res.0 == 2u64);
	assert(res.1 == 0u64);
	let res = divu64(0u64, 5u64, 2u64);
	assert(res.0 == 2u64);
	assert(res.1 == 1u64);
	let res = divu64(1u64, 0u64, 2u64);
	assert(res.0 == (1u64 << 63));
	assert(res.1 == 0u64);
	// These should panic.
	// let res = divu64(1u64, 1u64, 0u64);
	// let res = divu64(1u64, 0u64, 1u64);

	// divu()
	let res = divu(0u, 4u, 2u);
	assert(res.0 == 2u);
	assert(res.1 == 0u);
	let res = divu(0u, 5u, 2u);
	assert(res.0 == 2u);
	assert(res.1 == 1u);
	let res = divu(1u, 0u, 2u);
	assert(res.0 == (1u << 31));
	assert(res.1 == 0u);
	// These should panic.
	// divu(1u, 1u, 0u);
	// divu(1u, 0u, 1u);
};

// Returns the remainder of (hi, lo) divided by y.
// Panics for y == 0 (division by zero) but, unlike divu(), it doesn't panic on
// a quotient overflow.
export fn remu32(hi: u32, lo: u32, y: u32) u32 = {
	assert(y != 0);
	const res = ((hi: u64) << 32 | (lo: u64)) % (y: u64);
	return (res: u32);
};

// Returns the remainder of (hi, lo) divided by y.
// Panics for y == 0 (division by zero) but, unlike divu(), it doesn't panic on
// a quotient overflow.
export fn remu64(hi: u64, lo: u64, y: u64) u64 = {
	assert(y != 0);
	// We scale down hi so that hi < y, then use divu() to compute the
	// rem with the guarantee that it won't panic on quotient overflow.
	// Given that
	//   hi ≡ hi%y    (mod y)
	// we have
	//   hi<<64 + lo ≡ (hi%y)<<64 + lo    (mod y)
	const res = divu64(hi % y, lo, y);
	return res.1;
};

// Calls either remu32() or remu64() depending on size(uint).
export fn remu(hi: uint, lo: uint, y: uint) uint = {
	if (UINT_SIZE == 32) {
		return (remu32((hi: u32), (lo: u32), (y: u32)): uint);
	};
	return (remu64((hi: u64), (lo: u64), (y: u64)): uint);
};

@test fn remu() void = {
	// 32
	assert(remu32(0u32, 4u32, 2u32) == 0u32);
	assert(remu32(0u32, 5u32, 2u32) == 1u32);
	assert(remu32(0u32, 5u32, 3u32) == 2u32);
	assert(remu32(1u32, 1u32, 2u32) == 1u32);
	// These should panic.
	// remu32(0u32, 4u32, 0u32);

	// 64
	assert(remu64(0u64, 4u64, 2u64) == 0u64);
	assert(remu64(0u64, 5u64, 2u64) == 1u64);
	assert(remu64(0u64, 5u64, 3u64) == 2u64);
	assert(remu64(1u32, 1u32, 2u32) == 1u32);
	// These should panic.
	// remu64(0u64, 4u64, 0u64);

	// remu()
	assert(remu(0u, 4u, 2u) == 0u);
	assert(remu(0u, 5u, 2u) == 1u);
	assert(remu(0u, 5u, 3u) == 2u);
	assert(remu(1u, 1u, 2u) == 1u);
	// These should panic.
	// remu(0u, 4u, 0u);
};

// Returns the greatest common divisor of a and b.
export fn gcd(a: u64, b: u64) u64 = {
	if (a == b) {
		return a;
	};
	if (a == 0) {
		return b;
	};
	if (b == 0) {
		return a;
	};

	const i = trailing_zeros_u64(a);
	const j = trailing_zeros_u64(b);
	a >>= i;
	b >>= j;
	const k = if (i < j) i else j;

	for (true) {
		if (a > b) {
			const t = a;
			a = b;
			b = t;
		};

		b -= a;
		if (b == 0) {
			return a << k;
		};
		b >>= trailing_zeros_u64(b);
	};
};

@test fn gcd() void = {
	assert(gcd(2 * 3 * 5, 3 * 7) == 3);
	assert(gcd(2, 7) == 1);
	assert(gcd(2, 0) == 2);
	assert(gcd(0, 2) == 2);
	// gcd(123 * 2^55 * 3, 123 * 7)
	assert(gcd((123 << 55) * 3, 123 * 7) == 123);
};
