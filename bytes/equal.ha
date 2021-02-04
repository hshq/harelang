// Returns true if the two byte sequences are identical.
export fn equal(a: []u8, b: []u8) bool = {
	if (len(a) != len(b)) {
		return false;
	};
	for (let i = 0z; i < len(a); i += 1z) {
		if (a[i] != b[i]) {
			return false;
		};
	};
	return true;
};

@test fn equal() void = {
	let a: []u8 = [1u8, 2u8, 3u8];
	let b: []u8 = [1u8, 2u8, 3u8];
	let c: []u8 = [1u8, 4u8, 5u8];
	let d: []u8 = [1u8, 2u8, 3u8, 4u8];
	let e: []u8 = [1u8, 2u8];
	assert(equal(a, b));
	assert(!equal(a, c));
	assert(!equal(a, d));
	assert(!equal(a, e));
};
