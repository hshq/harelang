type string = struct {
	data: *[*]u8,
	length: size,
	capacity: size,
};

export fn strcmp(_a: str, _b: str) bool = {
	if (len(_a) != len(_b)) {
		return false;
	};
	let a = (&_a: *string).data, b = (&_b: *string).data;
	for (let i = 0z; i < len(_a); i += 1) {
		if (a[i] != b[i]) {
			return false;
		};
	};
	return true;
};
