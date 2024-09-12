// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
// (c) 2010 The Go Authors. All rights reserved.

def maxshift: u8 = 60;
def decimal_point_range: u16 = 2047;

type decimal = struct {
	// Numbers 0-9, not ascii, big endian. Length for small numbers is
	// log10(mantissa * 5^-exp). Subnormal doubles have min exp -1074 and
	// max mantissa 4e16, giving at most 767 digits.
	digits: [800]u8,

	// Number of valid digits. May be 0 if the number rounds to 0.
	nd: size,

	// Decimal point index, may be negative.
	// -1 means 0.0ddd..., 0 means 0.ddd..., 1 means d.dd..., and so on.
	dp: i32,

	negative: bool,

	// Were there nonzero digits beyond digits[0..nd]? This affects
	// rounding.
	truncated: bool,
};

// remove trailing zeroes
fn trim(d: *decimal) void = {
	for (d.nd > 0 && d.digits[d.nd - 1] == 0) {
		d.nd -= 1;
	};
};

fn leftshift_newdigits(d: *decimal, shift: u32) u32 = {
	shift &= 63;
	let x_a = left_shift_table[shift]: u32;
	let x_b = left_shift_table[shift + 1]: u32;
	let nn = x_a >> 11;
	let pow5_a = 0x7FF & x_a, pow5_b = 0x7FF & x_b;
	const p5 = pow5_table[pow5_a..];
	let i = 0u32, n = pow5_b - pow5_a;
	for (i < n; i += 1) {
		if (i >= d.nd) {
			return nn - 1;
		} else if (d.digits[i] == p5[i]) {
			continue;
		} else if (d.digits[i] < p5[i]) {
			return nn - 1;
		} else {
			return nn;
		};
	};
	return nn;
};

fn leftshift(d: *decimal, k: u32) void = {
	assert(k <= maxshift);
	if (d.nd == 0) return;
	let nn = leftshift_newdigits(d, k);
	let r = d.nd: int - 1, w = r: size + nn;
	let n = 0u64;
	for (r >= 0) {
		n += d.digits[r]: u64 << k;
		const quo = n / 10, rem = n - 10 * quo;
		if (w < len(d.digits)) {
			d.digits[w] = rem: u8;
		} else if (rem != 0) {
			d.truncated = true;
		};
		n = quo;
		r -= 1;
		w -= 1;
	};
	for (n > 0) {
		const quo = n / 10, rem = n - 10 * quo;
		if (w < len(d.digits)) {
			d.digits[w] = rem: u8;
		} else if (rem != 0) {
			d.truncated = true;
		};
		n = quo;
		w -= 1;
	};
	d.nd += nn;
	if (d.nd > len(d.digits)) {
		d.nd = len(d.digits);
	};
	d.dp += nn: i32;
	trim(d);
};

fn rightshift(d: *decimal, k: u32) void = {
	let r = 0z, w = 0z, n = 0u64;
	for (n >> k == 0; r += 1) {
		if (r >= d.nd) {
			if (n == 0) {
				d.nd = 0;
				return;
			};
			for (n >> k == 0; r += 1) {
				n *= 10;
			};
			break;
		};
		n = n * 10 + d.digits[r];
	};
	d.dp -= r: i32 - 1;
	if (d.dp < -(decimal_point_range: i32)) {
		*d = decimal { ... };
		return;
	};
	const mask = (1u64 << k) - 1;
	for (r < d.nd; r += 1) {
		const dig = n >> k;
		n &= mask;
		d.digits[w] = dig: u8;
		w += 1;
		n = n * 10 + d.digits[r];
	};
	for (n > 0) {
		const dig = n >> k;
		n &= mask;
		if (w < len(d.digits)) {
			d.digits[w] = dig: u8;
			w += 1;
		} else if (dig > 0) {
			d.truncated = true;
		};
		n *= 10;
	};
	d.nd = w;
	trim(d);
};

// Shift right (k < 0) or left (k > 0). We can only shift up to 60 at a time
// without losing bits, so break up big shifts.
fn decimal_shift(d: *decimal, k: int) void = {
	if (d.nd == 0) return;
	if (k > 0) {
		for (k > maxshift: int) {
			leftshift(d, maxshift);
			k -= maxshift: i32;
		};
		leftshift(d, k: u32);
	} else if (k < 0) {
		for (k < -(maxshift: int)) {
			rightshift(d, maxshift);
			k += maxshift: i32;
		};
		rightshift(d, (-k): u32);
	};
};

fn should_round_up(d: *decimal, nd: uint) bool = if (nd < d.nd) {
	if (d.digits[nd] == 5 && nd + 1 == d.nd) {
		return d.truncated ||
			(nd > 0 && d.digits[nd - 1] & 1 != 0);
	} else return d.digits[nd] >= 5;
} else false;

fn round(d: *decimal, nd: uint) void = {
	if (nd >= d.nd) return;
	if (should_round_up(d, nd)) roundup(d, nd)
	else rounddown(d, nd);
};

fn rounddown(d: *decimal, nd: uint) void = {
	if (nd >= d.nd) return;
	d.nd = nd;
	trim(d);
};

fn roundup(d: *decimal, nd: uint) void = {
	if (nd >= d.nd) return;
	for (let i = nd: int - 1; i >= 0; i -= 1) {
		if (d.digits[i] < 9) {
			d.digits[i] += 1;
			d.nd = i: size + 1;
			return;
		};
	};
	d.digits[0] = 1;
	d.nd = 1;
	d.dp += 1;
};

fn decimal_round(d: *decimal) u64 = {
	if (d.nd == 0 || d.dp < 0) return 0;
	if (d.dp > 18) return ~0u64;
	let i = 0z, n: u64 = 0;
	for (i < d.dp: uint && i < d.nd; i += 1) {
		n = n * 10 + d.digits[i];
	};
	for (i < d.dp: uint; i += 1) {
		n *= 10;
	};
	if (should_round_up(d, d.dp: uint)) {
		n += 1;
	};
	return n;
};
