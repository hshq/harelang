
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
	let x = fromhexmod("00000123", m);
	let y = fromhexmod("000003cf", m);
	let d = fromhexmod("00000000", m);

	const m0i = ninv31(m[1]);

	tomonty(x, m);
	tomonty(y, m);
	montymul(d, x, y, m, m0i);
	frommonty(d, m, m0i);

	assert(equalshex(d, "04544d"));

	free(d);
	free(x);
	free(y);

	d = fromhexmod("00000000", m);
	x = fromhexmod("0f98b7cf", m);
	y = fromhexmod("04216b9c", m);

	tomonty(x, m);
	tomonty(y, m);
	montymul(d, x, y, m, m0i);
	frommonty(d, m, m0i);

	assert(equalshex(d, "0d031f49"));

	free(x);
	free(y);
	free(m);
	free(d);
};
