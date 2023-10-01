// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

@test fn stoi() void = {
	assert(stoi64("") as invalid == 0: invalid);
	assert(stoi64("abc") as invalid == 0: invalid);
	assert(stoi64("1a") as invalid == 1: invalid);

	assert(stoi64("9223372036854775808") is overflow);
	assert(stoi64("-9223372036854775809") is overflow);

	assert(stoi64("0") as i64 == 0);
	assert(stoi64("1") as i64 == 1);
	assert(stoi64("+1") as i64 == 1);
	assert(stoi64("-1") as i64 == -1);
	assert(stoi64("9223372036854775807") as i64 == types::I64_MAX);
	assert(stoi64("-9223372036854775808") as i64 == types::I64_MIN);

	assert(stoi32("2147483648") is overflow);
	assert(stoi32("-2147483649") is overflow);

	assert(stoi32("2147483647") as i32 == 2147483647);
	assert(stoi32("-2147483648") as i32 == -2147483648);
};

@test fn stoib() void = {
	assert(stoi64b("-7f", 16) as i64 == -0x7f);
	assert(stoi64b("7F", 16) as i64 == 0x7f);
	assert(stoi64b("37", 8) as i64 == 0o37);
	assert(stoi64b("-110101", 2) as i64 == -0b110101);
};
