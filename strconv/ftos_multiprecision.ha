// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Multiprecision float to string based on golang's strconv/decimal.go.

use ascii;
use math;
use strings;

type mp = struct {
	// Numbers 0-9, not ascii. Length for small numbers is
	// log10(mantissa * 5^-exp). Subnormal doubles have min exp -1074 and
	// max mantissa 4e16, giving at most 767 digits.
	buf: [768]u8,
	// Number of valid digits in buf. May be 0 if the number rounds to 0.
	nd: uint,
	// Decimal point index, may be negative.
	// -1 means 0.0ddd...
	// 0 means 0.ddd...
	// 1 means d.dd...
	// and so on
	dp: int,
};

// These come from golang. The index into the table is amount of shift, up to
// 60. The number is the count of new digits that will be added by the shift,
// but one fewer if the number's prefix is smaller than the string prefix.
//
// For example, leftcheats[2] is (1, "25"). Any number left shifted by 2 will
// therefore be 1 digit longer, or zero digits longer if its first two digits
// are smaller than 25.
const leftcheats: [](size, str) = [
	(0, ""),
	(1, "5"),
	(1, "25"),
	(1, "125"),
	(2, "625"),
	(2, "3125"),
	(2, "15625"),
	(3, "78125"),
	(3, "390625"),
	(3, "1953125"),
	(4, "9765625"),
	(4, "48828125"),
	(4, "244140625"),
	(4, "1220703125"),
	(5, "6103515625"),
	(5, "30517578125"),
	(5, "152587890625"),
	(6, "762939453125"),
	(6, "3814697265625"),
	(6, "19073486328125"),
	(7, "95367431640625"),
	(7, "476837158203125"),
	(7, "2384185791015625"),
	(7, "11920928955078125"),
	(8, "59604644775390625"),
	(8, "298023223876953125"),
	(8, "1490116119384765625"),
	(9, "7450580596923828125"),
	(9, "37252902984619140625"),
	(9, "186264514923095703125"),
	(10, "931322574615478515625"),
	(10, "4656612873077392578125"),
	(10, "23283064365386962890625"),
	(10, "116415321826934814453125"),
	(11, "582076609134674072265625"),
	(11, "2910383045673370361328125"),
	(11, "14551915228366851806640625"),
	(12, "72759576141834259033203125"),
	(12, "363797880709171295166015625"),
	(12, "1818989403545856475830078125"),
	(13, "9094947017729282379150390625"),
	(13, "45474735088646411895751953125"),
	(13, "227373675443232059478759765625"),
	(13, "1136868377216160297393798828125"),
	(14, "5684341886080801486968994140625"),
	(14, "28421709430404007434844970703125"),
	(14, "142108547152020037174224853515625"),
	(15, "710542735760100185871124267578125"),
	(15, "3552713678800500929355621337890625"),
	(15, "17763568394002504646778106689453125"),
	(16, "88817841970012523233890533447265625"),
	(16, "444089209850062616169452667236328125"),
	(16, "2220446049250313080847263336181640625"),
	(16, "11102230246251565404236316680908203125"),
	(17, "55511151231257827021181583404541015625"),
	(17, "277555756156289135105907917022705078125"),
	(17, "1387778780781445675529539585113525390625"),
	(18, "6938893903907228377647697925567626953125"),
	(18, "34694469519536141888238489627838134765625"),
	(18, "173472347597680709441192448139190673828125"),
	(19, "867361737988403547205962240695953369140625"),
];

fn prefix_less_than_mp(m: *mp, s: str) bool = {
	const u = strings::toutf8(s);
	for (let i = 0z; i < len(s); i += 1) {
		if (i >= m.nd) {
			return true;
		};
		if (m.buf[i] + '0': u8 != u[i]) {
			return m.buf[i] + '0': u8 < u[i];
		};
	};
	return false;
};

// Shift left by k.
fn shl_mp(m: *mp, k: u64) void = {
	let delta = leftcheats[k].0;
	if (prefix_less_than_mp(m, leftcheats[k].1))
		delta -= 1;
	let r = (m.nd - 1): int;
	let w = m.nd + delta;
	let n = 0u64;
	for (r >= 0; r -= 1) {
		n += m.buf[r]: u64 << k;
		const quo = n / 10;
		const rem = n - 10 * quo;
		w -= 1;
		m.buf[w] = rem: u8;
		n = quo;
	};
	for (n > 0) {
		const quo = n / 10;
		const rem = n - 10 * quo;
		w -= 1;
		m.buf[w] = rem: u8;
		n = quo;
	};
	m.nd += delta: uint;
	m.dp += delta: int;
};

// Shift right by k.
fn shr_mp(m: *mp, k: u64) void = {
	let r = 0z;
	let w = 0z;
	let n = 0u64;
	const mask = (1 << k) - 1;

	for (n >> k == 0; r += 1) {
		if (r >= m.nd) {
			for (n >> k == 0) {
				n *= 10;
				r += 1;
			};
			break;
		};
		n = 10 * n + m.buf[r];
	};
	m.dp -= r: int - 1;

	for (r < m.nd; r += 1) {
		const c = m.buf[r];
		const dig = n >> k;
		n &= mask;
		m.buf[w] = dig: u8;
		w += 1;
		n = n * 10 + c;
	};

	for (n > 0; w += 1) {
		const dig = n >> k;
		n &= mask;
		m.buf[w] = dig: u8;
		n = n * 10;
	};
	m.nd = w: uint;
};

// Shift right (k < 0) or left (k > 0). We can only shift up to 60 at a time
// without losing bits, so break up big shifts.
fn shift_mp(m: *mp, k: int) void = {
	if (k < 0) {
		let nk = (-k): uint;
		for (nk > 60) {
			shr_mp(m, 60);
			nk -= 60;
		};
		shr_mp(m, nk);
	} else if (k > 0) {
		for (k > 60) {
			shl_mp(m, 60);
			k -= 60;
		};
		shl_mp(m, k: uint);
	};
};

fn init_mp(m: *mp, mantissa: u64, exponent: u32, eb: u64, mb: u64) void = {
	let e2 = (eb + mb): i32;
	let m2: u64 = 0;
	if (exponent == 0) {
		e2 = 1 - e2;
		m2 = mantissa;
	} else {
		e2 = (exponent: i32) - e2;
		m2 = (1u64 << mb) | mantissa;
	};

	m.nd = declen(m2);
	m.dp = m.nd: int;
	for (let i = 0z; i < m.nd; i += 1) {
		m.buf[m.nd - i - 1] = (m2 % 10): u8;
		m2 /= 10;
	};
	shift_mp(m, e2);
};

fn init_mp_dec(m: *mp, mantissa: u64, exponent: i32) void = {
	const dl = declen(mantissa);
	for (let i = 0u; i < dl; i += 1) {
		m.buf[dl - i - 1] = (mantissa % 10): u8;
		mantissa /= 10;
	};
	m.nd = dl;
	m.dp = dl: i32 + exponent;
};

fn round_up_mp(m: *mp) void = {
	for (let i = 1z; i <= m.nd; i += 1) {
		if (m.buf[m.nd - i] < 9) {
			m.buf[m.nd - i] += 1;
			return;
		} else {
			m.buf[m.nd - i] =  0;
		};
	};
	// All high
	m.buf[0] = 1;
	m.nd = 1;
	m.dp += 1;
};

// Compute the number of figs to round to for the given arguments.
fn compute_round_mp(m: *mp, f: ffmt, prec: (void | uint), flag: fflags) uint = {
	// nd is the number of sig figs that we want to end up with
	let nd: int = match (prec) {
	case void =>
		// we should only get here if Ryu did not extend past the
		// decimal point
		assert(ffpoint(flag));
		yield m.nd: int + (if (m.dp > 0) m.dp else 0);
	case let u: uint =>
		yield switch (f) {
		case ffmt::E =>
			yield u: int + 1;
		case ffmt::F =>
			yield u: int + m.dp;
		case ffmt::G =>
			yield if (u == 0) 1 else u: int;
		};
	};
	const nde = if (nd < 2) 2 else nd;
	const ndf = if (m.dp >= 0 && nd < m.dp + 1) m.dp + 1 else nd;
	if (ffpoint(flag)) {
		nd = switch (f) {
		case ffmt::E =>
			// need at least two digits, d.de0.
			yield nde;
		case ffmt::F =>
			// need enough to clear the decimal point by one.
			yield ndf;
		case ffmt::G =>
			// XXX: dup'd with the condition in ftosf_handle
			if (m.dp < -1 || m.dp - m.nd: int > 2)
				yield nde;
			yield ndf;
		};
	};
	if (nd <= 0) {
		nd = 0;
	};
	return if (nd: uint > m.nd) m.nd else nd: uint;
};

fn round_mp(m: *mp, nd: uint) void = {
	assert(nd <= m.nd);
	if (nd == m.nd)
		return;
	const oldnd = m.nd;
	m.nd = nd;
	if (m.buf[nd] > 5) {
		round_up_mp(m);
	} else if (m.buf[nd] == 5) {
		let gt = false;
		for (let i = m.nd + 1; i < oldnd; i += 1) {
			if (m.buf[i] > 0) {
				round_up_mp(m);
				gt = true;
				break;
			};
		};
		if (!gt && nd > 0 && m.buf[nd - 1] & 1 > 0) {
			round_up_mp(m);
		};
	};
};

// Remove trailing zeros.
fn trim_mp(m: *mp) void = {
	for (m.nd > 1 && m.buf[m.nd - 1] == 0) {
		m.nd -= 1;
	};
};
