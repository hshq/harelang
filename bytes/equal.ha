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
