use ascii;
use bytes;
use strings;

const maxshift: u8 = 60, decimal_point_range: u16 = 2047;

type decimal = struct {
	num_digits: size,
	decimal_point: int,
	negative: bool,
	truncated: bool,
	digits: [800]u8,
};

// remove trailing zeroes
fn trim(d: *decimal) void = {
	for (d.num_digits > 0 && d.digits[d.num_digits - 1] == 0) {
		d.num_digits -= 1;
	};
};

fn assign(d: *decimal, x: u64, negative: bool) void = {
	let sb = strings::toutf8(strconv::u64tos(x));
	let n = len(sb);
	for (let i = 0z; i < len(sb); i += 1) {
		sb[i] -= '0': u32: u8;
	};
	bytes::copy(d.digits[..n], sb[..n]);
	d.num_digits = n;
	d.negative = negative;
	d.truncated = false;
	trim(d);
};

const left_shift_table: [65]u16 = [
	0x0000, 0x0800, 0x0801, 0x0803, 0x1006, 0x1009, 0x100D, 0x1812, 0x1817,
	0x181D, 0x2024, 0x202B, 0x2033, 0x203C, 0x2846, 0x2850, 0x285B, 0x3067,
	0x3073, 0x3080, 0x388E, 0x389C, 0x38AB, 0x38BB, 0x40CC, 0x40DD, 0x40EF,
	0x4902, 0x4915, 0x4929, 0x513E, 0x5153, 0x5169, 0x5180, 0x5998, 0x59B0,
	0x59C9, 0x61E3, 0x61FD, 0x6218, 0x6A34, 0x6A50, 0x6A6D, 0x6A8B, 0x72AA,
	0x72C9, 0x72E9, 0x7B0A, 0x7B2B, 0x7B4D, 0x8370, 0x8393, 0x83B7, 0x83DC,
	0x8C02, 0x8C28, 0x8C4F, 0x9477, 0x949F, 0x94C8, 0x9CF2, 0x051C, 0x051C,
	0x051C, 0x051C,
];

const pow5_table: [0x051C]u8 = [
	5, 2, 5, 1, 2, 5, 6, 2, 5, 3, 1, 2, 5, 1, 5, 6, 2, 5, 7, 8, 1, 2, 5, 3,
	9, 0, 6, 2, 5, 1, 9, 5, 3, 1, 2, 5, 9, 7, 6, 5, 6, 2, 5, 4, 8, 8, 2, 8,
	1, 2, 5, 2, 4, 4, 1, 4, 0, 6, 2, 5, 1, 2, 2, 0, 7, 0, 3, 1, 2, 5, 6, 1,
	0, 3, 5, 1, 5, 6, 2, 5, 3, 0, 5, 1, 7, 5, 7, 8, 1, 2, 5, 1, 5, 2, 5, 8,
	7, 8, 9, 0, 6, 2, 5, 7, 6, 2, 9, 3, 9, 4, 5, 3, 1, 2, 5, 3, 8, 1, 4, 6,
	9, 7, 2, 6, 5, 6, 2, 5, 1, 9, 0, 7, 3, 4, 8, 6, 3, 2, 8, 1, 2, 5, 9, 5,
	3, 6, 7, 4, 3, 1, 6, 4, 0, 6, 2, 5, 4, 7, 6, 8, 3, 7, 1, 5, 8, 2, 0, 3,
	1, 2, 5, 2, 3, 8, 4, 1, 8, 5, 7, 9, 1, 0, 1, 5, 6, 2, 5, 1, 1, 9, 2, 0,
	9, 2, 8, 9, 5, 5, 0, 7, 8, 1, 2, 5, 5, 9, 6, 0, 4, 6, 4, 4, 7, 7, 5, 3,
	9, 0, 6, 2, 5, 2, 9, 8, 0, 2, 3, 2, 2, 3, 8, 7, 6, 9, 5, 3, 1, 2, 5, 1,
	4, 9, 0, 1, 1, 6, 1, 1, 9, 3, 8, 4, 7, 6, 5, 6, 2, 5, 7, 4, 5, 0, 5, 8,
	0, 5, 9, 6, 9, 2, 3, 8, 2, 8, 1, 2, 5, 3, 7, 2, 5, 2, 9, 0, 2, 9, 8, 4,
	6, 1, 9, 1, 4, 0, 6, 2, 5, 1, 8, 6, 2, 6, 4, 5, 1, 4, 9, 2, 3, 0, 9, 5,
	7, 0, 3, 1, 2, 5, 9, 3, 1, 3, 2, 2, 5, 7, 4, 6, 1, 5, 4, 7, 8, 5, 1, 5,
	6, 2, 5, 4, 6, 5, 6, 6, 1, 2, 8, 7, 3, 0, 7, 7, 3, 9, 2, 5, 7, 8, 1, 2,
	5, 2, 3, 2, 8, 3, 0, 6, 4, 3, 6, 5, 3, 8, 6, 9, 6, 2, 8, 9, 0, 6, 2, 5,
	1, 1, 6, 4, 1, 5, 3, 2, 1, 8, 2, 6, 9, 3, 4, 8, 1, 4, 4, 5, 3, 1, 2, 5,
	5, 8, 2, 0, 7, 6, 6, 0, 9, 1, 3, 4, 6, 7, 4, 0, 7, 2, 2, 6, 5, 6, 2, 5,
	2, 9, 1, 0, 3, 8, 3, 0, 4, 5, 6, 7, 3, 3, 7, 0, 3, 6, 1, 3, 2, 8, 1, 2,
	5, 1, 4, 5, 5, 1, 9, 1, 5, 2, 2, 8, 3, 6, 6, 8, 5, 1, 8, 0, 6, 6, 4, 0,
	6, 2, 5, 7, 2, 7, 5, 9, 5, 7, 6, 1, 4, 1, 8, 3, 4, 2, 5, 9, 0, 3, 3, 2,
	0, 3, 1, 2, 5, 3, 6, 3, 7, 9, 7, 8, 8, 0, 7, 0, 9, 1, 7, 1, 2, 9, 5, 1,
	6, 6, 0, 1, 5, 6, 2, 5, 1, 8, 1, 8, 9, 8, 9, 4, 0, 3, 5, 4, 5, 8, 5, 6,
	4, 7, 5, 8, 3, 0, 0, 7, 8, 1, 2, 5, 9, 0, 9, 4, 9, 4, 7, 0, 1, 7, 7, 2,
	9, 2, 8, 2, 3, 7, 9, 1, 5, 0, 3, 9, 0, 6, 2, 5, 4, 5, 4, 7, 4, 7, 3, 5,
	0, 8, 8, 6, 4, 6, 4, 1, 1, 8, 9, 5, 7, 5, 1, 9, 5, 3, 1, 2, 5, 2, 2, 7,
	3, 7, 3, 6, 7, 5, 4, 4, 3, 2, 3, 2, 0, 5, 9, 4, 7, 8, 7, 5, 9, 7, 6, 5,
	6, 2, 5, 1, 1, 3, 6, 8, 6, 8, 3, 7, 7, 2, 1, 6, 1, 6, 0, 2, 9, 7, 3, 9,
	3, 7, 9, 8, 8, 2, 8, 1, 2, 5, 5, 6, 8, 4, 3, 4, 1, 8, 8, 6, 0, 8, 0, 8,
	0, 1, 4, 8, 6, 9, 6, 8, 9, 9, 4, 1, 4, 0, 6, 2, 5, 2, 8, 4, 2, 1, 7, 0,
	9, 4, 3, 0, 4, 0, 4, 0, 0, 7, 4, 3, 4, 8, 4, 4, 9, 7, 0, 7, 0, 3, 1, 2,
	5, 1, 4, 2, 1, 0, 8, 5, 4, 7, 1, 5, 2, 0, 2, 0, 0, 3, 7, 1, 7, 4, 2, 2,
	4, 8, 5, 3, 5, 1, 5, 6, 2, 5, 7, 1, 0, 5, 4, 2, 7, 3, 5, 7, 6, 0, 1, 0,
	0, 1, 8, 5, 8, 7, 1, 1, 2, 4, 2, 6, 7, 5, 7, 8, 1, 2, 5, 3, 5, 5, 2, 7,
	1, 3, 6, 7, 8, 8, 0, 0, 5, 0, 0, 9, 2, 9, 3, 5, 5, 6, 2, 1, 3, 3, 7, 8,
	9, 0, 6, 2, 5, 1, 7, 7, 6, 3, 5, 6, 8, 3, 9, 4, 0, 0, 2, 5, 0, 4, 6, 4,
	6, 7, 7, 8, 1, 0, 6, 6, 8, 9, 4, 5, 3, 1, 2, 5, 8, 8, 8, 1, 7, 8, 4, 1,
	9, 7, 0, 0, 1, 2, 5, 2, 3, 2, 3, 3, 8, 9, 0, 5, 3, 3, 4, 4, 7, 2, 6, 5,
	6, 2, 5, 4, 4, 4, 0, 8, 9, 2, 0, 9, 8, 5, 0, 0, 6, 2, 6, 1, 6, 1, 6, 9,
	4, 5, 2, 6, 6, 7, 2, 3, 6, 3, 2, 8, 1, 2, 5, 2, 2, 2, 0, 4, 4, 6, 0, 4,
	9, 2, 5, 0, 3, 1, 3, 0, 8, 0, 8, 4, 7, 2, 6, 3, 3, 3, 6, 1, 8, 1, 6, 4,
	0, 6, 2, 5, 1, 1, 1, 0, 2, 2, 3, 0, 2, 4, 6, 2, 5, 1, 5, 6, 5, 4, 0, 4,
	2, 3, 6, 3, 1, 6, 6, 8, 0, 9, 0, 8, 2, 0, 3, 1, 2, 5, 5, 5, 5, 1, 1, 1,
	5, 1, 2, 3, 1, 2, 5, 7, 8, 2, 7, 0, 2, 1, 1, 8, 1, 5, 8, 3, 4, 0, 4, 5,
	4, 1, 0, 1, 5, 6, 2, 5, 2, 7, 7, 5, 5, 5, 7, 5, 6, 1, 5, 6, 2, 8, 9, 1,
	3, 5, 1, 0, 5, 9, 0, 7, 9, 1, 7, 0, 2, 2, 7, 0, 5, 0, 7, 8, 1, 2, 5, 1,
	3, 8, 7, 7, 7, 8, 7, 8, 0, 7, 8, 1, 4, 4, 5, 6, 7, 5, 5, 2, 9, 5, 3, 9,
	5, 8, 5, 1, 1, 3, 5, 2, 5, 3, 9, 0, 6, 2, 5, 6, 9, 3, 8, 8, 9, 3, 9, 0,
	3, 9, 0, 7, 2, 2, 8, 3, 7, 7, 6, 4, 7, 6, 9, 7, 9, 2, 5, 5, 6, 7, 6, 2,
	6, 9, 5, 3, 1, 2, 5, 3, 4, 6, 9, 4, 4, 6, 9, 5, 1, 9, 5, 3, 6, 1, 4, 1,
	8, 8, 8, 2, 3, 8, 4, 8, 9, 6, 2, 7, 8, 3, 8, 1, 3, 4, 7, 6, 5, 6, 2, 5,
	1, 7, 3, 4, 7, 2, 3, 4, 7, 5, 9, 7, 6, 8, 0, 7, 0, 9, 4, 4, 1, 1, 9, 2,
	4, 4, 8, 1, 3, 9, 1, 9, 0, 6, 7, 3, 8, 2, 8, 1, 2, 5, 8, 6, 7, 3, 6, 1,
	7, 3, 7, 9, 8, 8, 4, 0, 3, 5, 4, 7, 2, 0, 5, 9, 6, 2, 2, 4, 0, 6, 9, 5,
	9, 5, 3, 3, 6, 9, 1, 4, 0, 6, 2, 5,
];

fn leftshift_newdigits(d: *decimal, shift: u32) u32 = {
	shift &= 63;
	let x_a = left_shift_table[shift]: u32;
	let x_b = left_shift_table[shift + 1]: u32;
	let nn = x_a >> 11;
	let pow5_a = 0x7FF & x_a, pow5_b = 0x7FF & x_b;
	const p5 = pow5_table[pow5_a..];
	let i = 0u32, n = pow5_b - pow5_a;
	for (i < n; i += 1) {
		if (i >= d.num_digits) {
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

fn leftshift(d: *decimal, k: uint) void = {
	assert(k <= maxshift);
	if (d.num_digits == 0) return;
	let nn = leftshift_newdigits(d, k);
	let r = d.num_digits: int - 1, w = r: size + nn;
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
	d.num_digits += nn;
	if (d.num_digits > len(d.digits)) {
		d.num_digits = len(d.digits);
	};
	d.decimal_point += nn: int;
	trim(d);
};

fn rightshift(d: *decimal, k: uint) void = {
	let r = 0z, w = 0z, n = 0u64;
	for (n >> k == 0; r += 1) {
		if (r >= d.num_digits) {
			if (n == 0) {
				d.num_digits = 0;
				return;
			};
			for (n >> k == 0; r += 1) {
				n *= 10;
			};
			break;
		};
		n = n * 10 + d.digits[r];
	};
	d.decimal_point -= r: int - 1;
	const mask = (1u64 << k) - 1;
	for (r < d.num_digits; r += 1) {
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
	d.num_digits = w;
	trim(d);
};

fn decimal_shift(d: *decimal, k: int) void = {
	if (d.num_digits == 0) return;
	if (k > 0) {
		for (k > maxshift: int) {
			leftshift(d, maxshift);
			k -= maxshift: int;
		};
		leftshift(d, k: uint);
	} else if (k < 0) {
		for (k < -(maxshift: int)) {
			rightshift(d, maxshift);
			k += maxshift: int;
		};
		rightshift(d, (-k): uint);
	};
};

fn should_round_up(d: *decimal, nd: uint) bool = if (nd < d.num_digits) {
	if (d.digits[nd] == 5 && nd + 1 == d.num_digits) {
		return d.truncated ||
			 (nd > 0 && d.digits[nd - 1] & 1 != 0);
	} else return d.digits[nd] >= 5;
} else false;

fn decimal_round(d: *decimal) u64 = {
	if (d.num_digits == 0 && d.decimal_point < 0) return 0;
	if (d.decimal_point > 18) return ~0u64;
	let i = 0z, n: u64 = 0;
	for (i < d.decimal_point: uint && i < d.num_digits; i += 1) {
		n = n * 10 + d.digits[i];
	};
	for (i < d.decimal_point: uint; i += 1) {
		n *= 10;
	};
	if (should_round_up(d, d.decimal_point: uint)) {
		n += 1;
	};
	return n;
};

fn parse(s: str) (decimal | invalid) = {
	let i = 0z;
	let d = decimal { ... };
	if (len(s) == 0) return 0: invalid;
	const buf = strings::toutf8(s);
	d.negative = if (buf[0] == '+': u32: u8) {
		i += 1;
		false;
	} else if (buf[0] == '-': u32: u8) {
		i += 1;
		true;
	} else false;
	let sawdot = false, sawdigits = false;
	let nd: u32 = 0, dp: i32 = 0;
	for (i < len(s); i += 1) {
		if (buf[i] == '.': u32: u8) {
			if (sawdot) return i: invalid;
			sawdot = true;
			d.decimal_point = d.num_digits: int;
		} else if (ascii::isdigit(buf[i]: u32: rune)) {
			sawdigits = true;
			if (buf[i] == '0': u32: u8 && d.num_digits == 0) {
				d.decimal_point -= 1;
				continue;
			};
			if (d.num_digits < len(d.digits)) {
				d.digits[d.num_digits] = buf[i] - '0': u32: u8;
				d.num_digits += 1;
			} else if (buf[i] != '0': u32: u8) {
				d.truncated = true;
			};
		} else break;
	};
	if (!sawdigits) return i: invalid;
	if (!sawdot) {
		d.decimal_point = d.num_digits: int;
	};
	if (i < len(s) && (buf[i] == 'e': u32: u8 || buf[i] == 'E': u32: u8)) {
		i += 1;
		if (i >= len(s)) return i: invalid;
		const expsign: int = if (buf[i] == '+': u32: u8) {
			i += 1;
			1;
		} else if (buf[i] == '-': u32: u8) {
			i += 1;
			-1;
		} else 1;
		if (i >= len(s) || !ascii::isdigit(buf[i]: u32: rune)) return i: invalid;
		let e: int = 0;
		for (i < len(s) && ascii::isdigit(buf[i]: u32: rune); i += 1) {
			if (e < 10000) {
				e = e * 10 + buf[i]: int - '0': u32: int;
			};
		};
		d.decimal_point += e * expsign;
	};
	if (i != len(s)) return i: invalid;
	return d;
};

const powtab: [19]i8 = [
	1, 3, 6, 9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49, 53, 56, 59,
];

fn floatbits(d: decimal, mbits: u8, ebits: u8, ebias: i16) (u64 | overflow) = {
	let e: int = 0, m: u64 = 0, z = 1u64 << (mbits + ebits);
	if (d.num_digits == 0 || d.decimal_point < -326) {
		return if (d.negative) z else 0;
	};
	if (d.decimal_point > 310) {
		return overflow;
	};
	for (d.decimal_point > 0) {
		const n: int = if (d.decimal_point: uint >= len(powtab))
			maxshift: int
			else powtab[d.decimal_point];
		decimal_shift(&d, -n);
		e += n;
	};
	for (d.decimal_point <= 0) {
		const n: int = if (d.decimal_point == 0) {
			if (d.digits[0] >= 5) break; 
			if (d.digits[0] < 2) 2 else 1;
		} else if (-d.decimal_point >= len(powtab): int)
			maxshift: int
		else powtab[-d.decimal_point];
		decimal_shift(&d, n);
		e -= n;
	};
	e -= 1;
	if (e < -ebias + 1) {
		const n = -ebias - e + 1;
		decimal_shift(&d, -n);
		e += n;
	};
	if (e + ebias >= (1 << ebits: int) - 1) {
		return overflow;
	};
	decimal_shift(&d, mbits: int + 1);
	m = decimal_round(&d);
	if (m == 2 << mbits) {
		m >>= 1;
		e += 1;
		if (e + ebias >= (1 << ebits: int) - 1) {
			return overflow;
		};
	};
	if (m & (1u64 << mbits) == 0) {
		e = -ebias;
	};
	return mkf(m, (e + ebias): uint, mbits, ebits, d.negative);
};

fn mkf(m: u64, e: uint, mbits: u8, ebits: u8, negative: bool) u64 = {
	let n: u64 = m & ((1u64 << mbits) - 1);
	n |= (e & ((1u64 << ebits) - 1)) << mbits;
	if (negative) {
		n |= 1u64 << (mbits + ebits);
	};
	return n;
};

// Converts a string to a f64. If the string is not syntactically well-formed
// floating-point number in base 10, [[strconv::invalid]] is returned. If the
// string represents a floating-point number that is larger than the largest
// finite f64 number, [[strconv::overflow]] is returned. Zero with is returned
// if the string represents a floating-point number that is smaller than the f64
// number nearest to zero with respective sign.
export fn stof64(s: str) (f64 | invalid | overflow) = {
	const n = floatbits(parse(s)?, 52, 11, 1023)?;
	return *(&n: *f64);
};

@test fn stof64() void = {
	assert(stof64("0"): f64 == 0.0);
	assert(stof64("200"): f64 == 200.0);
	assert(stof64("12345"): f64 == 12345.0);
	assert(stof64("+112233445566778899"): f64 == 1.122334455667789e17);
	assert(stof64("3.14"): f64 == 3.14);
	assert(stof64("2.99792458E+8"): f64 == 299792458.0);
	assert(stof64("6.022e23"): f64 == 6.022e23);
	assert(stof64("2.2250738585072014e-308"): f64 == 2.2250738585072014e-308);
	assert(stof64("-1e-324"): f64 == -0.0);
	assert(stof64("1e309") is overflow);
	assert(stof64(""): invalid: size == 0);
	assert(stof64("0ZO"): invalid: size == 1);
	assert(stof64("1.23ezz"): invalid: size == 5);
};

