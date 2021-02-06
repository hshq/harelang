fn is_invalid_i64(value: (i64 | invalid | overflow)) bool = {
	return match (value) {
		invalid => true,
		* => false,
	};
};

fn is_overflow_i64(value: (i64 | invalid | overflow)) bool = {
	return match (value) {
		overflow => true,
		* => false,
	};
};

fn is_number_i64(n: i64, value: (i64 | invalid | overflow)) bool = {
	return match (value) {
		v: i64 => v == n,
		* => false,
	};
};

fn is_overflow_i32(value: (i32 | invalid | overflow)) bool = {
	return match (value) {
		overflow => true,
		* => false,
	};
};

fn is_number_i32(n: i32, value: (i32 | invalid | overflow)) bool = {
	return match (value) {
		v: i32 => v == n,
		* => false,
	};
};

@test fn stoi() void = {
	assert(is_invalid_i64(stoi64("")));
	assert(is_invalid_i64(stoi64("abc")));
	assert(is_invalid_i64(stoi64("1a")));

	assert(is_overflow_i64(stoi64("9223372036854775808")));
	assert(is_overflow_i64(stoi64("-9223372036854775809")));

	assert(is_number_i64(0i64, stoi64("0")));
	assert(is_number_i64(1i64, stoi64("1")));
	assert(is_number_i64(-1i64, stoi64("-1")));
	assert(is_number_i64(9223372036854775807i64, stoi64("9223372036854775807")));
	assert(is_number_i64(-9223372036854775808i64, stoi64("-9223372036854775808")));

	assert(is_overflow_i32(stoi32("2147483648")));
	assert(is_overflow_i32(stoi32("-2147483649")));

	assert(is_number_i32(2147483647i32, stoi32("2147483647")));
	assert(is_number_i32(-2147483648i32, stoi32("-2147483648")));
};
