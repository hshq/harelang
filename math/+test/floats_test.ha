// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@test fn floatbits() void = {
	const a: [_]f64 = [INF, -INF, 0.0, 1.0, -1.0, 123456789.0,
		F64_MIN, F64_MIN_NORMAL, F64_MAX_NORMAL];
	for (let i = 0z; i < len(a); i += 1) {
		assert(f64frombits(f64bits(a[i])) == a[i]);
	};
	const a: [_]f32 = [INF, -INF, 0.0, 1.0, -1.0, -123456.0,
		F32_MIN, F32_MIN_NORMAL, F32_MAX_NORMAL];
	for (let i = 0z; i < len(a); i += 1) {
		assert(f32frombits(f32bits(a[i])) == a[i]);
	};
};

@test fn isnan() void = {
	assert(isnan(NAN));
	assert(isnan(-NAN));
	assert(isnan(f64frombits(0xfffabcdef1234567)));
	assert(!isnan(INF));
	assert(!isnan(1.23f32));
};

@test fn float_normality() void = {
	assert(isnormal(0.0));
	assert(isnormal(1.0));
	assert(!isnormal(NAN));
	assert(!isnormal(INF));
	assert(!isnormal(1.0e-310));
	assert(!isnormal(1.0e-40f32));

	assert(isnormalf32(1.0));
	assert(isnormalf32(0.0));
	assert(!isnormalf32(NAN));
	assert(!isnormalf32(INF));
	assert(!isnormalf32(-1.0e-40));
	assert(isnormalf32(-1.0e-50));

	assert(isnormalf64(1.0));
	assert(isnormalf64(0.0));
	assert(!isnormalf64(NAN));
	assert(!isnormalf64(INF));
	assert(!isnormalf64(-1.0e-320));
	assert(isnormalf64(-1.0e-330));

	assert(issubnormal(1.0e-320));
	assert(issubnormal(1.0e-42f32));
	assert(!issubnormal(NAN));
	assert(!issubnormal(INF));
	assert(!issubnormal(1.0));
	assert(!issubnormal(0.0));

	assert(issubnormalf32(1.0e-45));
	assert(issubnormalf32(-1.0e-39));
	assert(!issubnormalf32(-NAN));
	assert(!issubnormalf32(-INF));
	assert(!issubnormalf32(0.0));
	assert(!issubnormalf32(-1.0e-49));

	assert(issubnormalf64(5.0e-324));
	assert(issubnormalf64(-2.0e-310));
	assert(!issubnormalf64(-NAN));
	assert(!issubnormalf64(-INF));
	assert(!issubnormalf64(-1.0e-400));
	assert(!issubnormalf64(0.0));
};

@test fn absf() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(absf(TEST_INPUTS[idx]) == TEST_ABSF[idx]);
	};
	assert(absf64(2f64) == 2f64);
	assert(absf32(2.0f32) == 2.0f32);
	assert(absf(2f64) == 2f64);
	assert(absf(2.0f32) == 2f64);
	assert(absf(-2f64) == 2f64);
	assert(absf(-2.0f32) == 2.0f32);
	assert(absf(0f32) == 0f32);
	assert(absf(0f64) == 0f64);
};

@test fn copysign() void = {
	assert(copysign(100f64, 1f64) == 100f64);
	assert(copysign(100f64, -1f64) == -100f64);
	assert(copysign(100.0f32, 1.0f32) == 100.0f32);
	assert(copysign(100.0f32, -1.0f32) == -100.0f32);
	assert(copysign(100f64, 0f64) == 100f64);
	assert(copysign(100f64, -0f64) == -100f64);
	assert(copysign(0f64, 100f64) == 0f64);
	assert(signf(copysign(0f64, 100f64)) > 0);
	assert(copysign(0f64, -100f64) == 0f64);
	assert(signf(copysign(0f64, -100f64)) < 0);
};

@test fn signf() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(signf(TEST_INPUTS[idx]) == TEST_SIGNF[idx]);
	};
	assert(signf(0f64) == 1i64);
	assert(signf(-0f64) == -1i64);
	assert(signf(0.0f32) == 1i64);
	assert(signf(-0.0f32) == -1i64);
	assert(signf(1.5f64) == 1i64);
	assert(signf(-1.5f64) == -1i64);
	assert(ispositive(1f64));
	assert(!ispositive(-1f64));
	assert(isnegative(-1f64));
	assert(!isnegative(1f64));
};

@test fn normalize() void = {
	let res = normalizef64(5.0e-320);
	assert(res.0 > F64_MIN_NORMAL);
	assert(res.1 < 0i64);
	res = normalizef64(5.0e-300);
	assert(res.0 == 5.0e-300);
	assert(res.1 == 0i64);
};

@test fn frexp() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		let res = frexp(TEST_INPUTS[idx]);
		let expected = TEST_FREXP[idx];
		assert(res.0 == expected.0);
		assert(res.1 == expected.1);
	};
	let res = frexp(3f64);
	assert(res.0 == 0.75f64);
	assert(res.1 == 2i64);
	res = frexp(2.42f64);
	assert(res.0 == 0.605f64);
	assert(res.1 == 2i64);
	res = frexp(NAN);
	assert(res.1 == 0);
	res = frexp(INF);
	assert(res.1 == 0);
};

@test fn frexp_ldexp() void = {
	const tests64: [_]f64 = [INF, -INF,
		0.0, 1.0, -1.0, 2.42, 123456789.0,
		F64_MIN_NORMAL, F64_MAX_NORMAL,
		3.0e-310f64];
	for (let i = 0z; i < len(tests64); i += 1) {
		const parts = frexpf64(tests64[i]);
		const res64 = ldexpf64(parts.0, parts.1);
		assert(res64 == tests64[i]);
	};
	assert(ldexpf64(1f64, -1076i64) == 0f64);
	assert(ldexpf64(-1f64, -1076i64) == -0f64);
	assert(signf(ldexpf64(-1f64, -1076i64)) < 0);
	assert(ldexpf64(2f64, 1024i64) == INF);
	assert(ldexpf64(-2f64, 1024i64) == -INF);

	const tests32: [_]f32 = [INF, -INF,
		0.0, 1.0, -1.0, 2.42, 123456789.0,
		F32_MIN_NORMAL, F32_MAX_NORMAL,
		3.0e-39f32];
	for (let i = 0z; i < len(tests32); i += 1) {
		const parts = frexpf32(tests32[i]);
		const res = ldexpf32(parts.0, parts.1);
		assert(res == tests32[i]);
	};
	assert(ldexpf32(1.0f32, -1076i32) == 0.0f32);
	assert(ldexpf32(-1.0f32, -1076i32) == -0.0f32);
	assert(signf(ldexpf32(-1.0f32, -1076i32)) < 0);
	assert(ldexpf32(2.0f32, 1024i32) == INF);
	assert(ldexpf32(-2.0f32, 1024i32) == -INF);
};

@test fn modfrac() void = {
	// 64
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		let res = modfracf64(TEST_INPUTS[idx]);
		assert(res.0 == TEST_MODFRAC[idx].0);
		assert(isclose(res.1, TEST_MODFRAC[idx].1));
	};
	let res = modfracf64(1.75f64);
	assert(res.0 == 1f64);
	assert(res.1 == 0.75f64);
	res = modfracf64(0.75f64);
	assert(res.0 == 0f64);
	assert(res.1 == 0.75f64);
	res = modfracf64(-0.75f64);
	assert(res.0 == -0f64);
	assert(res.1 == -0.75f64);
	res = modfracf64(0f64);
	assert(res.0 == 0f64);
	assert(res.1 == 0f64);
	assert(signf(res.1) > 0);
	res = modfracf64(-0f64);
	assert(res.0 == -0f64);
	assert(res.1 == -0f64);
	assert(signf(res.1) < 0);
	res = modfracf64(23.50f64);
	assert(res.0 == 23f64);
	assert(res.1 == 0.50f64);
	res = modfracf64(F64_MAX_NORMAL);
	assert(res.0 == F64_MAX_NORMAL);
	assert(res.1 == 0f64);

	// 32
	let res = modfracf32(1.75f32);
	assert(res.0 == 1f32);
	assert(res.1 == 0.75f32);
	res = modfracf32(0.75f32);
	assert(res.0 == 0f32);
	assert(res.1 == 0.75f32);
	res = modfracf32(-0.75f32);
	assert(res.0 == -0f32);
	assert(res.1 == -0.75f32);
	res = modfracf32(0.0f32);
	assert(res.0 == 0f32);
	assert(res.1 == 0.0f32);
	assert(signf(res.1) > 0);
	res = modfracf32(-0.0f32);
	assert(res.0 == -0f32);
	assert(res.1 == -0.0f32);
	assert(signf(res.1) < 0);
	res = modfracf32(23.50f32);
	assert(res.0 == 23f32);
	assert(res.1 == 0.50f32);
	res = modfracf32(F32_MAX_NORMAL);
	assert(res.0 == F32_MAX_NORMAL);
	assert(res.1 == 0f32);
};

@test fn nextafter() void = {
	let f = &f64frombits;
	// from musl's testsuite
	assert(nextafterf64(f(0xc0202239f3c6a8f1), f(0x40122484b9ef31f0)) == f(0xc0202239f3c6a8f0));
	assert(nextafterf64(f(0x401161868e18bc67), f(0xc021c6a6cdce75e8)) == f(0x401161868e18bc66));
	assert(nextafterf64(f(0xc020c34b3e01e6e7), f(0xc0061bde29e83f6d)) == f(0xc020c34b3e01e6e6));
	assert(nextafterf64(f(0xc01a206f0a19dcc4), f(0x40124527f7b576ac)) == f(0xc01a206f0a19dcc3));
	assert(nextafterf64(f(0x402288bbb0d6a1e6), f(0x40133edd910a3c01)) == f(0x402288bbb0d6a1e5));
	assert(nextafterf64(f(0xc019ccd8be03f495), f(0x3fe52fb12ef638a1)) == f(0xc019ccd8be03f494));
	assert(nextafterf64(f(0x401f6f80ed2eab44), f(0x3faab3ff8575b21d)) == f(0x401f6f80ed2eab43));
	assert(nextafterf64(f(0xbfe95882b433fad3), f(0x401eb4a2e7ce0693)) == f(0xbfe95882b433fad2));
	assert(nextafterf64(f(0x3fe3b3d617ae3c4a), f(0x40001860611d75e1)) == f(0x3fe3b3d617ae3c4b));
	assert(nextafterf64(f(0xbfe1e159e36313ee), f(0x3fa081bd34224213)) == f(0xbfe1e159e36313ed));

	assert(nextafterf64(f(0xbfe1e159e36313ee), f(0xbfe1e159e36313ee)) == f(0xbfe1e159e36313ee));
	assert(nextafterf64(0.0f64, 1.0f64) == f(0x1));
	assert(nextafterf64(0.0f64, -1.0f64) == f(0x8000000000000001));
	assert(nextafterf64(-0.0f64, 1.0f64) == f(0x1));
	assert(nextafterf64(-0.0f64, -1.0f64) == f(0x8000000000000001));
	assert(nextafterf64(0.0f64, 0.0f64) == 0.0f64);
	assert(nextafterf64(-0.0f64, 0.0f64) == 0.0f64);
	assert(nextafterf64(0.0f64, -0.0f64) == -0.0f64);
	assert(isnan(nextafterf64(1.0f64, NAN)));
	assert(isnan(nextafterf64(NAN, -2f64)));
	assert(isnan(nextafterf64(NAN, NAN)));

	let f = &f32frombits;
	assert(nextafterf32(f(0xc10111d0), f(0x40912426)) == f(0xc10111cf));
	assert(nextafterf32(f(0x408b0c34), f(0xc10e3536)) == f(0x408b0c33));
	assert(nextafterf32(f(0xc1061a5a), f(0xc030def1)) == f(0xc1061a59));
	assert(nextafterf32(f(0xc0d10378), f(0x40922940)) == f(0xc0d10377));
	assert(nextafterf32(f(0x411445de), f(0x4099f6ed)) == f(0x411445dd));
	assert(nextafterf32(f(0xc0ce66c6), f(0x3f297d89)) == f(0xc0ce66c5));
	assert(nextafterf32(f(0x40fb7c07), f(0x3d559ffc)) == f(0x40fb7c06));
	assert(nextafterf32(f(0xbf4ac416), f(0x40f5a517)) == f(0xbf4ac415));
	assert(nextafterf32(f(0x3f1d9eb1), f(0x4000c303)) == f(0x3f1d9eb2));
	assert(nextafterf32(f(0xbf0f0acf), f(0x3d040dea)) == f(0xbf0f0ace));

	assert(nextafterf32(f(0xbf0f0acf), f(0xbf0f0acf)) == f(0xbf0f0acf));
	assert(nextafterf32(0.0f32, 1.0f32) == f(0x1));
	assert(nextafterf32(0.0f32, -1.0f32) == f(0x80000001));
	assert(nextafterf32(-0.0f32, 1.0f32) == f(0x1));
	assert(nextafterf32(-0.0f32, -1.0f32) == f(0x80000001));
	assert(nextafterf32(0.0f32, 0.0f32) == 0.0f32);
	assert(nextafterf32(-0.0f32, 0.0f32) == 0.0f32);
	assert(nextafterf32(0.0f32, -0.0f32) == -0.0f32);
	assert(isnan(nextafterf32(1.0f32, NAN)));
	assert(isnan(nextafterf32(NAN, -2f32)));
	assert(isnan(nextafterf32(NAN, NAN)));
};

@test fn nearbyint() void = {
	// from musl's testsuite
	let f = &f64frombits;
	assert(nearbyintf64(f(0xc0202239f3c6a8f1)) == f(0xc020000000000000));
	assert(nearbyintf64(f(0x401161868e18bc67)) == f(0x4010000000000000));
	assert(nearbyintf64(f(0xc020c34b3e01e6e7)) == f(0xc020000000000000));
	assert(nearbyintf64(f(0xc01a206f0a19dcc4)) == f(0xc01c000000000000));
	assert(nearbyintf64(f(0x402288bbb0d6a1e6)) == f(0x4022000000000000));
	assert(nearbyintf64(f(0x3fe52efd0cd80497)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbfda05cc754481d1)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3fe1f9ef934745cb)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0x3fe8c5db097f7442)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbfe5b86ea8118a0e)) == f(0xbff0000000000000));

	let f = &f32frombits;
	assert(nearbyintf32(f(0xc10111d0)) == f(0xc1000000));
	assert(nearbyintf32(f(0x408b0c34)) == f(0x40800000));
	assert(nearbyintf32(f(0xc1061a5a)) == f(0xc1000000));
	assert(nearbyintf32(f(0xc0d10378)) == f(0xc0e00000));
	assert(nearbyintf32(f(0x411445de)) == f(0x41100000));
	assert(nearbyintf32(f(0x3f2977e8)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbed02e64)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f0fcf7d)) == f(0x3f800000));
	assert(nearbyintf32(f(0x3f462ed8)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf2dc375)) == f(0xbf800000));
};
