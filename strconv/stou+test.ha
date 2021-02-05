fn is_invalid64(value: (u64 | invalid | overflow)) bool = {
	return match (value) {
		invalid => true,
		* => false,
	};
};

fn is_overflow64(value: (u64 | invalid | overflow)) bool = {
	return match (value) {
		overflow => true,
		* => false,
	};
};

fn is_number64(n: u64, value: (u64 | invalid | overflow)) bool = {
	return match (value) {
		v: u64 => v == n,
		* => false,
	};
};

@test fn stou() void = {
	assert(is_invalid64(stou64("")));
	assert(is_invalid64(stou64("abc")));
	assert(is_invalid64(stou64("1a")));
	assert(is_invalid64(stou64("-1")));

	assert(is_overflow64(stou64("18446744073709551616")));
	assert(is_overflow64(stou64("184467440737095516150")));

	assert(is_number64(0u64, stou64("0")));
	assert(is_number64(1u64, stou64("1")));
	assert(is_number64(18446744073709551615u64, stou64("18446744073709551615")));
};
