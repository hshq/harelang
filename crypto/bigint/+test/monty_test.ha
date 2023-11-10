// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@test fn montyencode() void = {
	let m = fromhex("0010000061");
	let x = fromhexmod("0000010064", m);

	defer free(x);
	defer free(m);

	const m0i = ninv31(m[1]);

	tomonty(x, m);
	frommonty(x, m, m0i);

	assert(equalshex(x, "010064"));
};

@test fn montymul() void = {
	let m = fromhex("10000061");
	defer free(m);
	let x = fromhexmod("00000123", m);
	defer free(x);
	let y = fromhexmod("000003cf", m);
	defer free(y);
	let d = fromhexmod("00000000", m);
	defer free(d);

	const m0i = ninv31(m[1]);

	tomonty(x, m);
	tomonty(y, m);
	montymul(d, x, y, m, m0i);
	frommonty(d, m, m0i);

	assert(equalshex(d, "04544d"));

	let d = fromhexmod("00000000", m);
	defer free(d);
	let x = fromhexmod("0f98b7cf", m);
	defer free(x);
	let y = fromhexmod("04216b9c", m);
	defer free(y);

	tomonty(x, m);
	tomonty(y, m);
	montymul(d, x, y, m, m0i);
	frommonty(d, m, m0i);

	assert(equalshex(d, "0d031f49"));
};
