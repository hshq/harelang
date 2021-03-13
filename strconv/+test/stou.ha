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

@test fn stoub() void = {
	assert(is_number64(0x7fu64, stou64b("7f", 16u)));
	assert(is_number64(0x7fu64, stou64b("7F", 16u)));
	assert(is_number64(0o37u64, stou64b("37", 8u)));
	assert(is_number64(0b110101u64, stou64b("110101", 2u)));
};
