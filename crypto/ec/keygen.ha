// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;


// Generates a random private key scalar suitable for given curve 'c'.
// 'rand' must be cryptographic random stream like the one provided by
// [[crypto::random::stream]].
export fn keygen(c: *curve, priv: []u8, rand: io::handle) (size | io::error) =
	c.keygen(c, priv, rand);

// A keygen that generates random keys until one is found that fits within
// the order of curve 'c'.
fn mask_keygen(
	c: *curve,
	priv: []u8,
	rand: io::handle
) (size | io::error) = {
	const order = c.order();
	assert(len(priv) == len(order));
	assert(order[0] != 0);

	// mask all bits until including the highest value one.
	let mask = order[0];
	mask |= (mask >> 1);
	mask |= (mask >> 2);
	mask |= (mask >> 4);

	for (true) {
		match (io::readall(rand, priv)?) {
		case let s: size =>
			assert(s == len(priv));
		case io::EOF =>
			return (0: io::underread): io::error;
		};
		priv[0] &= mask;

		if (validate_scalar(c, priv) is void) {
			return len(priv);
		};
	};
};
