// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Checks whether the point is encoded in the curves point format. Does NOT
// check if it is a valid point on the curve. For such point validation use
// [[validate_point]].
export fn validate_pointformat(c: *curve, p: []u8) (void | invalid) = {
	if (len(p) != c.pointsz || p[0] != 0x04) {
		return invalid;
	};
};

// Checks if given point is properly encoded and a valid point on given curve
// 'c'. This operation is quite expensive. Note that in any case point
// validation will be done on every mul and muladd operation.
export fn validate_point(c: *curve, p: []u8) (void | invalid) = {
	validate_pointformat(c, p)?;

	static let scalarbuf: [MAX_POINTSZ]u8 = [0...];
	let scalarbuf = scalarbuf[..len(c.order())];
	scalarbuf[len(scalarbuf) - 1] = 1;

	if (c.mul(p, scalarbuf) == 0) {
		return invalid;
	};
};

// Validates if given scalar is less than the curve order and greater then zero.
export fn validate_scalar(c: *curve, n: []u8) (void | invalid) = {
	const order = c.order();
	let cc: u16 = 0;
	let zz: u8 = 0;
	for (let i = len(n); i > 0; i -= 1) {
		// subtraction with carry
		cc = ((n[i - 1]: u16 - order[i - 1] - cc) >> 8) & 1;
		zz |= n[i - 1];
	};

	// cc == 0 means the carry is not set because order < priv
	if (cc == 0 || zz == 0) {
		return invalid;
	};
};
