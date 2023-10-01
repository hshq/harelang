// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@test fn trig_reduce() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		const reduced = trig_reduce(TEST_INPUTS[idx]);
		const j = reduced.0;
		const z = reduced.1;
		const xred = (j: i64: f64) * (PI / 4f64) + z;
		assert(isclose(
			sinf64(TEST_INPUTS[idx]),
			sinf64(xred)));
	};
};

@test fn cos() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			cosf64(TEST_INPUTS[idx]), TEST_COS[idx]));
	};
	assert(isnan(cosf64(-INF)));
	assert(isnan(cosf64(INF)));
	assert(isnan(cosf64(NAN)));
};

@test fn sin() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			sinf64(TEST_INPUTS[idx]), TEST_SIN[idx]));
	};
	assert(isnan(sinf64(-INF)));
	assert(sinf64(-0f64) == -0f64);
	assert(sinf64(0f64) == 0f64);
	assert(isnan(sinf64(INF)));
	assert(isnan(sinf64(NAN)));
};

@test fn tan() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			tanf64(TEST_INPUTS[idx]), TEST_TAN[idx]));
	};
	assert(isnan(sinf64(-INF)));
	assert(sinf64(-0f64) == -0f64);
	assert(sinf64(0f64) == 0f64);
	assert(isnan(sinf64(INF)));
	assert(isnan(sinf64(NAN)));
};

@test fn asin() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			asinf64(TEST_INPUTS[idx] / 10f64),
			TEST_ASIN[idx]));
	};
	assert(isnan(asinf64(-PI)));
	assert(asinf64(-0f64) == -0f64);
	assert(asinf64(0f64) == 0f64);
	assert(isnan(asinf64(PI)));
	assert(isnan(asinf64(NAN)));
};

@test fn acos() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			acosf64(TEST_INPUTS[idx] / 10f64),
			TEST_ACOS[idx]));
	};
	assert(isnan(acosf64(-PI)));
	assert(acosf64(1f64) == 0f64);
	assert(isnan(acosf64(PI)));
	assert(isnan(acosf64(NAN)));
};

@test fn atan() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			atanf64(TEST_INPUTS[idx]),
			TEST_ATAN[idx]));
	};
	assert(atanf64(-INF) == -PI / 2f64);
	assert(atanf64(-0f64) == -0f64);
	assert(atanf64(0f64) == 0f64);
	assert(atanf64(INF) == PI / 2f64);
	assert(isnan(atanf64(NAN)));
};

@test fn sinh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(eqwithin(
			sinhf64(TEST_INPUTS[idx]),
			TEST_SINH[idx],
			1e-6f64));
	};
	assert(sinhf64(-INF) == -INF);
	assert(sinhf64(-0f64) == -0f64);
	assert(sinhf64(0f64) == 0f64);
	assert(sinhf64(INF) == INF);
	assert(isnan(sinhf64(NAN)));
};

@test fn cosh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			coshf64(TEST_INPUTS[idx]),
			TEST_COSH[idx]));
	};
	assert(coshf64(-INF) == INF);
	assert(coshf64(-0f64) == 1f64);
	assert(coshf64(0f64) == 1f64);
	assert(coshf64(INF) == INF);
	assert(isnan(coshf64(NAN)));
};

@test fn tanh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			tanhf64(TEST_INPUTS[idx]),
			TEST_TANH[idx]));
	};
	assert(tanhf64(-INF) == -1f64);
	assert(tanhf64(-0f64) == -0f64);
	assert(tanhf64(0f64) == 0f64);
	assert(tanhf64(INF) == 1f64);
	assert(isnan(tanhf64(NAN)));
};

@test fn asinh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			asinhf64(TEST_INPUTS[idx]),
			TEST_ASINH[idx]));
	};
	assert(asinhf64(-INF) == -INF);
	assert(asinhf64(-0f64) == -0f64);
	assert(asinhf64(0f64) == 0f64);
	assert(asinhf64(INF) == INF);
	assert(isnan(asinhf64(NAN)));
};

@test fn acosh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			acoshf64(1f64 + absf64(TEST_INPUTS[idx])),
			TEST_ACOSH[idx]));
	};
	assert(isnan(acoshf64(-INF)));
	assert(isnan(acoshf64(0.5f64)));
	assert(acoshf64(1f64) == 0f64);
	assert(acoshf64(INF) == INF);
	assert(isnan(acoshf64(NAN)));
};

@test fn atanh() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			atanhf64(TEST_INPUTS[idx] / 10f64),
			TEST_ATANH[idx]));
	};
	assert(isnan(atanhf64(-INF)));
	assert(isnan(atanhf64(-PI)));
	assert(atanhf64(-1f64) == -INF);
	assert(atanhf64(-0f64) == -0f64);
	assert(atanhf64(0f64) == 0f64);
	assert(atanhf64(1f64) == INF);
	assert(isnan(atanhf64(PI)));
	assert(isnan(atanhf64(INF)));
	assert(isnan(atanhf64(NAN)));
};

@test fn atan2() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			atan2f64(10f64, TEST_INPUTS[idx]),
			TEST_ATAN2[idx]));
	};
	assert(isnan(atan2f64(-INF, NAN)));
	assert(atan2f64(-PI, INF) == -0f64);
	assert(isnan(atan2f64(-PI, NAN)));
	assert(atan2f64(-0f64, 0f64) == -0f64);
	assert(atan2f64(-0f64, PI) == -0f64);
	assert(atan2f64(-0f64, INF) == -0f64);
	assert(isnan(atan2f64(-0f64, NAN)));
	assert(atan2f64(0f64, 0f64) == 0f64);
	assert(atan2f64(0f64, PI) == 0f64);
	assert(atan2f64(0f64, INF) == 0f64);
	assert(isnan(atan2f64(0f64, NAN)));
	assert(atan2f64(PI, INF) == 0f64);
	assert(atan2f64(1f64, INF) == 0f64);
	assert(atan2f64(-1f64, INF) == -0f64);
	assert(isnan(atan2f64(PI, NAN)));
	assert(isnan(atan2f64(INF, NAN)));
	assert(isnan(atan2f64(NAN, NAN)));
};

@test fn hypot() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		const a = absf64(1e200f64 * TEST_TANH[idx] * SQRT_2);
		assert(isclose(
			hypotf64(1e200f64 * TEST_TANH[idx],
				1e200f64 * TEST_TANH[idx]),
			a));
	};
	assert(hypotf64(-INF, -INF) == INF);
	assert(hypotf64(-INF, 0f64) == INF);
	assert(hypotf64(-INF, INF) == INF);
	assert(hypotf64(-INF, NAN) == INF);
	assert(hypotf64(-0f64, -0f64) == 0f64);
	assert(hypotf64(-0f64, 0f64) == 0f64);
	assert(hypotf64(0f64, -0f64) == 0f64);
	assert(hypotf64(0f64, 0f64) == 0f64);
	assert(hypotf64(0f64, -INF) == INF);
	assert(hypotf64(0f64, INF) == INF);
	assert(isnan(hypotf64(0f64, NAN)));
	assert(hypotf64(INF, -INF) == INF);
	assert(hypotf64(INF, 0f64) == INF);
	assert(hypotf64(INF, INF) == INF);
	assert(hypotf64(INF, NAN) == INF);
	assert(hypotf64(NAN, -INF) == INF);
	assert(isnan(hypotf64(NAN, 0f64)));
	assert(hypotf64(NAN, INF) == INF);
	assert(isnan(hypotf64(NAN, NAN)));
};
