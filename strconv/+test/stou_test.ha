// License: MPL-2.0
// (c) 2021 Andri Yngvason <andri@yngvason.is>
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

@test fn stou() void = {
	assert(stou64("") as invalid == 0: invalid);
	assert(stou64("abc") as invalid == 0: invalid);
	assert(stou64("1a") as invalid == 1: invalid);
	assert(stou64("-1") as invalid == 0: invalid);

	assert(stou64("18446744073709551616") is overflow);
	assert(stou64("184467440737095516150") is overflow);

	assert(stou64("0") as u64 == 0);
	assert(stou64("1") as u64 == 1);
	assert(stou64("18446744073709551615") as u64 == 18446744073709551615);
};

@test fn stoub() void = {
	assert(stou64b("7f", 16) as u64 == 0x7f);
	assert(stou64b("7F", 16) as u64 == 0x7f);
	assert(stou64b("37", 8) as u64 == 0o37);
	assert(stou64b("110101", 2) as u64 == 0b110101);
};
