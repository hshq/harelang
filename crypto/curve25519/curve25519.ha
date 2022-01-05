// Implements the curve25519 elliptic curve

// Implementations used for reference
//
// Kleppmann: https://martin.kleppmann.com/papers/curve25519.pdf
// OpenSSL: https://github.com/openssl/openssl/blob/master/crypto/ec/curve25519.c
// Go: https://github.com/golang/crypto/blob/master/curve25519/curve25519.go
// TweetNaCl: https://tweetnacl.cr.yp.to/

// The size of the scalar input to X25519.
export def SCALARSZ: size = 32;

// The size of the point input to X25519.
export def POINTSZ: size = 32;

// The canonical Curve25519 generator
export const BASEPOINT: [POINTSZ]u8 = [9, 0...];

// Compute the result of the scalar multiplication (scalar * point) and put the
// result in out.
export fn x25519(
	out: *[SCALARSZ]u8,
	scalar: const *[SCALARSZ]u8,
	point: const *[POINTSZ]u8
) void = {
	scalarmult(out, scalar, point);
};

// Compute the result of the scalar multiplication (scalar * point) where point
// is BASEPOINT.
export fn scalarmult_base(
	out: *[SCALARSZ]u8,
	scalar: const *[SCALARSZ]u8
) void = {
	scalarmult(out, scalar, &BASEPOINT);
};

// Set out to the product (scalar * point)
export fn scalarmult(
	out: *[SCALARSZ]u8,
	scalar: const *[SCALARSZ]u8,
	point: const *[POINTSZ]u8
) void = {
	let clamped: [32]u8 = *scalar;
	clamped[0] &= 0xf8;
	clamped[31] = (clamped[31] & 0x7f) | 0x40;
	let x = unpack25519(point);
	let b: elem = *&x;
	let a: elem = [1, 0...];
	let c: elem = [0...];
	let d: elem = [1, 0...];
	let e: elem = [0...];
	let f: elem = [0...];

	for (let i = 254i; i >= 0; i -= 1) {
		let iz = i : size;
		let bit = ((clamped[iz >> 3] >> (iz & 7)) & 1) : i64;
		swap25519(&a, &b, bit);
		swap25519(&c, &d, bit);
		addfe(&e, &a, &c);
		subfe(&a, &a, &c);
		addfe(&c, &b, &d);
		subfe(&b, &b, &d);
		mulfe(&d, &e, &e);
		mulfe(&f, &a, &a);
		mulfe(&a, &c, &a);
		mulfe(&c, &b, &e);
		addfe(&e, &a, &c);
		subfe(&a, &a, &c);
		mulfe(&b, &a, &a);
		subfe(&c, &d, &f);
		mulfe(&a, &c, &_121665);
		addfe(&a, &a, &d);
		mulfe(&c, &c, &a);
		mulfe(&a, &d, &f);
		mulfe(&d, &b, &x);
		mulfe(&b, &e, &e);
		swap25519(&a, &b, bit);
		swap25519(&c, &d, bit);
	};

	invfe(&c, &c);
	mulfe(&a, &a, &c);
	pack25519(out, &a);
};

// An internal representation used for arithmetic operations.
def FIELDSZ: size = 16;
type elem = [FIELDSZ]i64;

// Constant used in scalar multiplication.
const _121665: elem = [0xdb41, 1, 0...];

fn unpack25519(in: *[SCALARSZ]u8) elem = {
	let fe: elem = [0...];

	for (let i = 0z; i < FIELDSZ; i += 1) {
		fe[i] = in[2 * i] : i64 + ((in[2 * i + 1] : i64) << 8);
	};
	fe[15] &= 0x7fff;

	return fe;
};

fn carry25519(fe: *elem) void = {
	let carry = 0i64;

	for (let i = 0z; i < FIELDSZ; i += 1) {
		carry = fe[i] >> 16;
		fe[i] -= (carry << 16);
		if (i < 15) {
			fe[i + 1] += carry;
		} else {
			fe[0] += (38 * carry);
		};
	};
};

// Set out = a + b
fn addfe(out: *elem, a: const *elem, b: const *elem) void = {
	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[i] = a[i] + b[i];
	};
};

// Set out = a - b
fn subfe(out: *elem, a: const *elem, b: const *elem) void = {
	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[i] = a[i] - b[i];
	};
};

// Set out = a * b
fn mulfe(out: *elem, a: const *elem, b: const *elem) void = {
	let product: [31]i64 = [0...];

	for (let i = 0z; i < FIELDSZ; i += 1) {
		for (let j = 0z; j < FIELDSZ; j += 1) {
			product[i + j] += a[i] * b[j];
		};
	};

	for (let i = 0z; i < 15; i += 1) {
		product[i] += (38 * product[i + 16]);
	};
	out[0..FIELDSZ] = product[0..FIELDSZ];

	carry25519(out);
	carry25519(out);
};

// Compute the multiplicative inverse
fn invfe(out: *elem, a: const *elem) void = {
	let c: elem = *a;
	for (let i = 253i; i >= 0; i -= 1) {
		mulfe(&c, &c, &c);
		if (i != 2 && i != 4) {
			mulfe(&c, &c, a);
		};
	};
	out[..] = c[..];
};

// Swap inputs p and q, if bit is 1, do nothing if bit is 0.
//
// If bit is 1, this function swaps the content of parameters p and q (both in
// elem representation), and it does nothing if bit is 0. As bit may be
// part of a secret value, this function cannot use a simple if statement,
// because that would not be constant-time
fn swap25519(p: *elem, q: *elem, bit: i64) void = {
	let c = ~(bit : u64 - 1) : i64;
	for (let i = 0z; i < FIELDSZ; i += 1) {
		let t = c & (p[i] ^ q[i]);
		p[i] ^= t;
		q[i] ^= t;
	};
};

fn pack25519(out: *[SCALARSZ]u8, a: const *elem) void = {
	let m: elem = [0...];
	let t: elem = *a;

	carry25519(&t);
	carry25519(&t);
	carry25519(&t);

	for (let _i = 0z; _i < 2; _i += 1) {
		m[0] = t[0] - 0xffed;
		for (let i = 1z; i < 15; i += 1) {
			m[i] = t[i] - 0xffff - ((m[i - 1] >> 16) & 1);
			m[i - 1] &= 0xffff;
		};
		m[15] = t[15] - 0x7fff - ((m[14] >> 16) & 1);
		let carry = (m[15] >> 16) & 1;
		m[14] &= 0xffff;
		swap25519(&t, &m, 1 - carry);
	};

	for (let i = 0z; i < FIELDSZ; i += 1) {
		out[2 * i] = (t[i] & 0xff) : u8;
		out[2 * i + 1] = (t[i] >> 8) : u8;
	};
};
