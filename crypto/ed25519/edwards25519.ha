// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

def FIELDSZ: size = 16;
type elem = [FIELDSZ]i64;

const feZero: elem = [0...];
const feOne: elem = [1, 0...];
const D: elem = [0x78a3, 0x1359, 0x4dca, 0x75eb, 0xd8ab, 0x4141, 0x0a4d, 0x0070, 0xe898, 0x7779, 0x4079, 0x8cc7, 0xfe73, 0x2b6f, 0x6cee, 0x5203];
const D2: elem = [0xf159, 0x26b2, 0x9b94, 0xebd6, 0xb156, 0x8283, 0x149a, 0x00e0, 0xd130, 0xeef3, 0x80f2, 0x198e, 0xfce7, 0x56df, 0xd9dc, 0x2406];
const X: elem = [0xd51a, 0x8f25, 0x2d60, 0xc956, 0xa7b2, 0x9525, 0xc760, 0x692c, 0xdc5c, 0xfdd6, 0xe231, 0xc0a4, 0x53fe, 0xcd6e, 0x36d3, 0x2169];
const Y: elem = [0x6658, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666];
const I: elem = [0xa0b0, 0x4a0e, 0x1b27, 0xc4ee, 0xe478, 0xad2f, 0x1806, 0x2f43, 0xd7a7, 0x3dfb, 0x0099, 0x2b4d, 0xdf0b, 0x4fc1, 0x2480, 0x2b83];

fn fe_reduce(fe: *elem) void = {
	let carry: i64 = 0;
	for (let i = 0z; i < FIELDSZ; i += 1) {
		carry = fe[i] >> 16;
		fe[i] -= (carry << 16);
		if (i+1 < FIELDSZ) {
			fe[i + 1] += carry;
		} else {
			fe[0] += (38 * carry);
		};
	};
};

fn fe_add(out: *elem, a: const *elem, b: const *elem) *elem = {
	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[i] = a[i] + b[i];
	};
	return out;
};

fn fe_sub(out: *elem, a: const *elem, b: const *elem) *elem = {
	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[i] = a[i] - b[i];
	};
	return out;
};

fn fe_negate(out: *elem, a: const *elem) *elem = {
	return fe_sub(out, &feZero, a);
};

fn fe_mul(out: *elem, a: const *elem, b: const *elem) *elem = {
	let prod: [31]i64 = [0...];
	for (let i = 0z; i < FIELDSZ; i += 1) {
		for (let j = 0z; j < FIELDSZ; j += 1) {
			prod[i + j] += a[i] * b[j];
		};
	};
	for (let i = 0; i < 15; i += 1) {
		prod[i] += (38 * prod[i + 16]);
	};
	out[0..FIELDSZ] = prod[0..FIELDSZ];
	fe_reduce(out);
	fe_reduce(out);
	return out;
};

fn fe_square(out: *elem, a: const *elem) *elem = {
	return fe_mul(out, a, a);
};

// out = i ** (2**252 - 3)
fn fe_pow2523(out: *elem, a: *elem) *elem = {
	let c: elem = [0...];
	c[..] = a[..];
	for (let i = 250i; i >= 0; i -= 1) {
		fe_square(&c, &c);
		if (i != 1) {
			fe_mul(&c, &c, a);
		};
	};
	out[..] = c[..];
	return out;
};

fn fe_inv(out: *elem, a: const *elem) *elem = {
	let c: elem = [0...];
	c[..] = a[..];
	for (let i = 253i; i >= 0; i -= 1) {
		fe_square(&c, &c);
		if (i != 2 && i != 4) {
			fe_mul(&c, &c, a);
		};
	};
	out[..] = c[..];
	return out;
};

fn fe_parity(a: const *elem) u8 = {
	let d: scalar = [0...];
	fe_encode(&d, a);
	return d[0]&1;
};

// a == b -> 0
// a != b -> 1
fn fe_cmp(a: const *elem, b: const *elem) u8 = {
	let x: scalar = [0...];
	fe_encode(&x, a);
	let y: scalar = [0...];
	fe_encode(&y, b);

	// constant-time compare
	let d: u32 = 0;
	for (let i = 0z; i < SCALARSZ; i += 1) {
		d |= x[i] ^ y[i];
	};
	return (1 & ((d - 1) >> 8): u8) - 1;
};

// swap p and q if bit is 1, otherwise noop
fn fe_swap(p: *elem, q: *elem, bit: u8) void = {
	let c = ~(bit: u64 - 1): i64;
	for (let i = 0z; i < FIELDSZ; i += 1) {
		let t = c & (p[i] ^ q[i]);
		p[i] ^= t;
		q[i] ^= t;
	};
};

fn fe_encode(out: *scalar, a: const *elem) void = {
	let m: elem = [0...];
	let t: elem = *a;

	fe_reduce(&t);
	fe_reduce(&t);
	fe_reduce(&t);

	for (let _i = 0; _i < 2; _i += 1) {
		m[0] = t[0] - 0xffed;
		for (let i = 1z; i < 15; i += 1) {
			m[i] = t[i] - 0xffff - ((m[i - 1] >> 16) & 1);
			m[i - 1] &= 0xffff;
		};
		m[15] = t[15] - 0x7fff - ((m[14] >> 16) & 1);
		let b = ((m[15] >> 16): u8) & 1;
		m[14] &= 0xffff;
		fe_swap(&t, &m, 1-b);
	};

	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[2*i+0] = (t[i] & 0xff) : u8;
		out[2*i+1] = (t[i] >> 8) : u8;
	};
};

// len(in) must be SCALARSZ
fn fe_decode(fe: *elem, in: []u8) *elem = {
	for (let i = 0z; i < FIELDSZ; i += 1) {
		fe[i] = in[2 * i] : i64 + ((in[2 * i + 1] : i64) << 8);
	};
	fe[15] &= 0x7fff;
	return fe;
};


def SCALARSZ: size = 32;
type scalar = [SCALARSZ]u8;

const L: scalar = [
	0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58, 0xd6, 0x9c, 0xf7, 0xa2,
	0xde, 0xf9, 0xde, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10,
];

fn scalar_clamp(s: *scalar) void = {
	s[0] &= 248;
	s[31] &= 127;
	s[31] |= 64;
};

// r = x % -1
fn scalar_mod_L(r: *scalar, x: *[64]i64) void = {
	for (let i: i64 = 63; i >= 32; i -= 1) {
		let carry: i64 = 0;
		let j = i - 32;
		for (j < i - 12; j += 1) {
			x[j] += carry - 16 * x[i] * (L[j - (i - 32)]: i64);
			carry = (x[j] + 128) >> 8;
			x[j] -= carry << 8;
		};
		x[j] += carry;
		x[i] = 0;
	};

	let carry: i64 = 0;
	for (let j = 0; j < 32; j += 1) {
		x[j] += carry - (x[31] >> 4) * (L[j]: i64);
		carry = x[j] >> 8;
		x[j] &= 255;
	};
	for (let j = 0; j < 32; j += 1) {
		x[j] -= carry * (L[j]: i64);
	};
	for (let i = 0; i < 32; i += 1) {
		x[i+1] += x[i] >> 8;
		r[i] = (x[i]&255): u8;
	};
};

fn scalar_reduce(r: *scalar, h: *[64]u8) void = {
	let x: [64]i64 = [0...];
	for (let i = 0; i < 64; i += 1) {
		x[i] = h[i]: i64;
	};
	scalar_mod_L(r, &x);
};

// s = a*b + c
fn scalar_multiply_add(s: *scalar, a: *scalar, b: *scalar, c: *scalar) void = {
	let x: [64]i64 = [0...];
	for (let i = 0; i < 32; i += 1) {
		for (let j = 0; j < 32; j += 1) {
			x[i+j] += (a[i]: i64) * (b[j]: i64);
		};
	};
	for (let i = 0; i < 32; i += 1) {
		x[i] += (c[i]: i64);
	};
	scalar_mod_L(s, &x);
};


def POINTSZ: size = 32;

type point = struct {
	x: elem,
	y: elem,
	z: elem,
	t: elem,
};

// out = p += q
fn point_add(out: *point, p: *point, q: *point) *point = {
	let a: elem = [0...];
	let b: elem = [0...];
	let c: elem = [0...];
	let d: elem = [0...];
	let t: elem = [0...];
	let e: elem = [0...];
	let f: elem = [0...];
	let g: elem = [0...];
	let h: elem = [0...];

	fe_sub(&a, &p.y, &p.x);
	fe_sub(&t, &q.y, &q.x);
	fe_mul(&a, &a, &t);
	fe_add(&b, &p.x, &p.y);
	fe_add(&t, &q.x, &q.y);
	fe_mul(&b, &b, &t);
	fe_mul(&c, &p.t, &q.t);
	fe_mul(&c, &c, &D2);
	fe_mul(&d, &p.z, &q.z);
	fe_add(&d, &d, &d);
	fe_sub(&e, &b, &a);
	fe_sub(&f, &d, &c);
	fe_add(&g, &d, &c);
	fe_add(&h, &b, &a);

	fe_mul(&out.x, &e, &f);
	fe_mul(&out.y, &h, &g);
	fe_mul(&out.z, &g, &f);
	fe_mul(&out.t, &e, &h);
	return out;
};

// swap p and q if bit is 1, otherwise noop
fn point_swap(p: *point, q: *point, bit: u8) void = {
	fe_swap(&p.x, &q.x, bit);
	fe_swap(&p.y, &q.y, bit);
	fe_swap(&p.z, &q.z, bit);
	fe_swap(&p.t, &q.t, bit);
};

// p = q * s
fn scalarmult(p: *point, q: *point, s: const *scalar) *point = {
	p.x[..] = feZero[..];
	p.y[..] = feOne[..];
	p.z[..] = feOne[..];
	p.t[..] = feZero[..];
	for (let i = 255; i >= 0; i -= 1) {
		let b: u8 = (s[i/8]>>((i: u8)&7))&1;
		point_swap(p, q, b);
		point_add(q, q, p);
		point_add(p, p, p);
		point_swap(p, q, b);
	};
	return p;
};

// p = B * s
fn scalarmult_base(p: *point, s: const *scalar) *point = {
	let B = point {...};
	B.x[..] = X[..];
	B.y[..] = Y[..];
	B.z[..] = feOne[..];
	fe_mul(&B.t, &X, &Y);

	return scalarmult(p, &B, s);
};

fn point_encode(out: *scalar, p: *point) void = {
	let tx: elem = [0...];
	let ty: elem = [0...];
	let zi: elem = [0...];
	fe_inv(&zi, &p.z);
	fe_mul(&tx, &p.x, &zi);
	fe_mul(&ty, &p.y, &zi);
	fe_encode(out, &ty);
	out[31] ^= fe_parity(&tx) << 7;
};

// len(in) must be POINTSZ
fn point_decode(p: *point, in: []u8) bool = {
	let t: elem = [0...];
	let chk: elem = [0...];
	let num: elem = [0...];
	let den: elem = [0...];
	let den2: elem = [0...];
	let den4: elem = [0...];
	let den6: elem = [0...];
	p.z[..] = feOne[..];
	fe_decode(&p.y, in);
	fe_square(&num, &p.y);
	fe_mul(&den, &num, &D);
	fe_sub(&num, &num, &p.z);
	fe_add(&den, &p.z, &den);

	fe_square(&den2, &den);
	fe_square(&den4, &den2);
	fe_mul(&den6, &den4, &den2);
	fe_mul(&t, &den6, &num);
	fe_mul(&t, &t, &den);

	fe_pow2523(&t, &t);
	fe_mul(&t, &t, &num);
	fe_mul(&t, &t, &den);
	fe_mul(&t, &t, &den);
	fe_mul(&p.x, &t, &den);

	fe_square(&chk, &p.x);
	fe_mul(&chk, &chk, &den);
	if (fe_cmp(&chk, &num) != 0) {
		fe_mul(&p.x, &p.x, &I);
	};

	fe_square(&chk, &p.x);
	fe_mul(&chk, &chk, &den);
	if (fe_cmp(&chk, &num) != 0) {
		return false;
	};

	if (fe_parity(&p.x) == (in[31]>>7)) {
		fe_negate(&p.x, &p.x);
	};

	fe_mul(&p.t, &p.x, &p.y);
	return true;
};
