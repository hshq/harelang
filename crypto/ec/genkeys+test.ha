// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use io;
use memio;


@test fn keygen_p256() void = edgecases(p256);
@test fn keygen_p384() void = edgecases(p384);
@test fn keygen_p521() void = edgecases(p521);

fn edgecases(c: *curve) void = {
	const scalarsz = len(c.order());
	let priv: [MAX_SCALARSZ]u8 = [0...];
	let priv = priv[..scalarsz];

	let zero: [MAX_SCALARSZ]u8 = [0...];
	let zero = zero[..scalarsz];

	let rnd = memio::fixed(zero);
	assert(keygen(c, priv, &rnd) is io::error);

	let rnd = memio::fixed(c.order());
	assert(keygen(c, priv, &rnd) is io::error);

	let sub1: [MAX_SCALARSZ]u8 = [0...];
	let sub1 = sub1[..scalarsz];

	sub1[..] = c.order()[..];
	sub1[len(sub1) - 1] -= 1;

	let rnd = memio::fixed(sub1);
	assert(keygen(c, priv, &rnd): size == scalarsz);
	assert(bytes::equal(sub1, priv));
};
