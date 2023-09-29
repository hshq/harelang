// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@test fn eqwithin() void = {
	assert(eqwithin(1f64, 2f64, 2f64));
	assert(eqwithin(1.0f32, 2.0f32, 2.0f32));
	assert(!eqwithin(1.0005f32, 1.0004f32, 0.00001f32));
	assert(isclose(1f64, 1.0000000000000000000000000001f64));
	assert(isclose(1.0f32, 1.0000000000000000000000000001f32));
	assert(!isclose(1.0005f32, 1.0004f32));
};

@test fn logf64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(
			logf64(absf64(TEST_INPUTS[idx])),
			TEST_LOG[idx]));
	};
	assert(logf64(E) == 1f64);
	assert(logf64(54.598150033144239078110261202860878402790f64) == 4f64);
	assert(isnan(logf64(-1f64)));
	assert(logf64(INF) == INF);
	assert(logf64(0f64) == -INF);
	assert(isnan(logf64(NAN)));
};

@test fn log10f64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(
			log10f64(absf64(TEST_INPUTS[idx])),
			TEST_LOG10[idx]));
	};
};

@test fn log2f64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(
			log2f64(absf64(TEST_INPUTS[idx])),
			TEST_LOG2[idx]));
	};
};

@test fn log1p() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			log1pf64(TEST_INPUTS[idx] / 100f64),
			TEST_LOG1P[idx]));
	};
	assert(isnan(log1pf64(-INF)));
	assert(isnan(log1pf64(-PI)));
	assert(log1pf64(-1f64) == -INF);
	assert(log1pf64(-0f64) == -0f64);
	assert(log1pf64(0f64) == 0f64);
	assert(log1pf64(INF) == INF);
	assert(isnan(log1pf64(NAN)));
};

@test fn expf64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(expf64(TEST_INPUTS[idx]), TEST_EXP[idx]));
	};
	assert(expf64(1f64) == E);
	assert(isnan(expf64(NAN)));
	assert(isinf(expf64(INF)));
	assert(expf64(-INF) == 0f64);
	assert(isinf(expf64(99999f64)));
	assert(expf64(-99999f64) == 0f64);
	assert(expf64(0.5e-20) == 1f64);
};

@test fn exp2f64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(exp2f64(TEST_INPUTS[idx]), TEST_EXP2[idx]));
	};
	assert(exp2f64(0f64) == 1f64);
	assert(exp2f64(3f64) == 8f64);
	assert(exp2f64(-2f64) == 0.25f64);
	assert(!isinf(exp2f64(256f64)));
	assert(isinf(exp2f64(99999f64)));
	assert(exp2f64(-99999f64) == 0f64);
	assert(isnan(exp2f64(NAN)));
	assert(isinf(exp2f64(INF)));
	assert(exp2f64(-INF) == 0f64);
};

@test fn sqrt() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(isclose(
			sqrtf64(absf64(TEST_INPUTS[idx])),
			TEST_SQRT[idx]));
	};
	assert(sqrtf64(2f64) == SQRT_2);
	assert(sqrtf64(4f64) == 2f64);
	assert(sqrtf64(16f64) == 4f64);
	assert(sqrtf64(65536f64) == 256f64);
	assert(sqrtf64(powf64(123f64, 2f64)) == 123f64);
	assert(sqrtf64(0f64) == 0f64);
	assert(isnan(sqrtf64(NAN)));
	assert(sqrtf64(INF) == INF);
	assert(isnan(sqrtf64(-2f64)));
};

@test fn powf64() void = {
	for (let idx = 0z; idx < len(TEST_INPUTS); idx += 1) {
		assert(eqwithin(
			powf64(10f64, TEST_INPUTS[idx]),
			TEST_POW[idx],
			1e-8f64));
	};
	// Positive integer
	assert(powf64(2f64, 2f64) == 4f64);
	assert(powf64(3f64, 3f64) == 27f64);
	// Very large positive integer
	assert(!isinf(powf64(2f64, 1020f64)));
	assert(isinf(powf64(2f64, 1050f64)));
	// Very very large positive integer
	assert(isinf(powf64(2f64, F64_MAX_NORMAL)));
	assert(powf64(0.5f64, F64_MAX_NORMAL) == 0f64);
	// Negative integer
	assert(powf64(2f64, -1f64) == 0.5f64);
	assert(powf64(2f64, -2f64) == 0.25f64);
	// Very small negative integer
	assert(powf64(2f64, -1020f64) > 0f64);
	assert(powf64(2f64, -1080f64) == 0f64);
	// Very very small negative integer
	assert(powf64(2f64, -F64_MAX_NORMAL) == 0f64);
	assert(isinf(powf64(0.5f64, -F64_MAX_NORMAL)));
	// Positive fractional powers
	assert(eqwithin(powf64(2f64, 1.5f64),
		2.8284271247461900976033774f64,
		1e-10f64));
	assert(eqwithin(powf64(2f64, 5.5f64),
		45.254833995939041561654039f64,
		1e-10f64));
	// Negative fractional powers
	assert(eqwithin(powf64(2f64, -1.5f64),
		0.3535533905932737622004221f64,
		1e-10f64));
	assert(eqwithin(powf64(2f64, -5.5f64),
		0.0220970869120796101375263f64,
		1e-10f64));

	// Special cases
	// pow(x, ±0) = 1 for any x
	assert(powf64(123f64, 0f64) == 1f64);
	// pow(1, y) = 1 for any y
	assert(powf64(1f64, 123f64) == 1f64);
	// pow(x, 1) = x for any x
	assert(powf64(123f64, 1f64) == 123f64);
	// pow(NaN, y) = NaN
	assert(isnan(powf64(NAN, 123f64)));
	// pow(x, NaN) = NaN
	assert(isnan(powf64(123f64, NAN)));
	// pow(±0, y) = ±Inf for y an odd integer < 0
	assert(powf64(0f64, -3f64) == INF);
	assert(powf64(-0f64, -3f64) == -INF);
	// pow(±0, -Inf) = +Inf
	assert(powf64(0f64, -INF) == INF);
	assert(powf64(-0f64, -INF) == INF);
	// pow(±0, +Inf) = +0
	assert(powf64(0f64, INF) == 0f64);
	assert(powf64(-0f64, INF) == 0f64);
	// pow(±0, y) = +Inf for finite y < 0 and not an odd integer
	assert(powf64(0f64, -2f64) == INF);
	assert(powf64(0f64, -2f64) == INF);
	//pow(±0, y) = ±0 for y an odd integer > 0
	assert(powf64(0f64, 123f64) == 0f64);
	const neg_zero = powf64(-0f64, 123f64);
	assert(neg_zero == 0f64);
	assert(isnegative(neg_zero));
	// pow(±0, y) = +0 for finite y > 0 and not an odd integer
	assert(powf64(0f64, 8f64) == 0f64);
	// pow(-1, ±Inf) = 1
	assert(powf64(-1f64, INF) == 1f64);
	assert(powf64(-1f64, -INF) == 1f64);
	// pow(x, +Inf) = +Inf for |x| > 1
	assert(powf64(123f64, INF) == INF);
	// pow(x, -Inf) = +0 for |x| > 1
	assert(powf64(123f64, -INF) == 0f64);
	// pow(x, +Inf) = +0 for |x| < 1
	assert(powf64(0.5f64, INF) == 0f64);
	assert(powf64(-0.5f64, INF) == 0f64);
	// pow(x, -Inf) = +Inf for |x| < 1
	assert(powf64(0.5f64, -INF) == INF);
	assert(powf64(-0.5f64, -INF) == INF);
	// pow(+Inf, y) = +Inf for y > 0
	assert(powf64(INF, 123f64) == INF);
	// pow(+Inf, y) = +0 for y < 0
	assert(powf64(INF, -1f64) == 0f64);
	// pow(-Inf, y) = pow(-0, -y)
	assert(powf64(-INF, 123f64) == powf64(-0f64, -123f64));
	// pow(x, y) = NaN for finite x < 0 and finite non-integer y
	assert(isnan(powf64(-2f64, 1.23f64)));
	// sqrt
	assert(powf64(4f64, 0.5f64) == sqrtf64(4f64));
	assert(powf64(4f64, 0.5f64) == 2f64);
	assert(powf64(4f64, -0.5f64) == (1f64 / sqrtf64(4f64)));
	assert(powf64(4f64, -0.5f64) == (1f64 / 2f64));
};

@test fn floor() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			floorf64(TEST_INPUTS[idx]),
				TEST_FLOOR[idx]));
	};
	assert(floorf64(-INF) == -INF);
	assert(floorf64(-0f64) == -0f64);
	assert(floorf64(0f64) == 0f64);
	assert(floorf64(INF) == INF);
	assert(isnan(floorf64(NAN)));
};

@test fn ceil() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			ceilf64(TEST_INPUTS[idx]),
				TEST_CEIL[idx]));
	};
	assert(ceilf64(-INF) == -INF);
	assert(ceilf64(-F64_MAX_NORMAL) == -F64_MAX_NORMAL);
	assert(ceilf64(-0f64) == -0f64);
	assert(ceilf64(0f64) == 0f64);
	assert(ceilf64(F64_MAX_NORMAL) == F64_MAX_NORMAL);
	assert(ceilf64(INF) == INF);
	assert(isnan(ceilf64(NAN)));
};

@test fn trunc() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			truncf64(TEST_INPUTS[idx]),
			TEST_TRUNC[idx]));
	};
	assert(truncf64(-INF) == -INF);
	assert(truncf64(-F64_MAX_NORMAL) == -F64_MAX_NORMAL);
	assert(truncf64(-0f64) == -0f64);
	assert(truncf64(0f64) == 0f64);
	assert(truncf64(F64_MAX_NORMAL) == F64_MAX_NORMAL);
	assert(truncf64(INF) == INF);
	assert(isnan(truncf64(NAN)));
};

@test fn round() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			roundf64(TEST_INPUTS[idx]),
				TEST_ROUND[idx]));
	};
	assert(roundf64(-INF) == -INF);
	assert(roundf64(-F64_MAX_NORMAL) == -F64_MAX_NORMAL);
	assert(roundf64(-0f64) == -0f64);
	assert(roundf64(0f64) == 0f64);
	assert(roundf64(F64_MAX_NORMAL) == F64_MAX_NORMAL);
	assert(roundf64(INF) == INF);
	assert(isnan(roundf64(NAN)));
};

@test fn modf64() void = {
	for (let idx = 0z; idx < 10; idx += 1) {
		assert(isclose(
			modf64(10f64, TEST_INPUTS[idx]),
			TEST_MODF[idx]));
	};

	assert(isnan(modf64(-INF, -INF)));
	assert(isnan(modf64(-INF, -PI)));
	assert(isnan(modf64(-INF, 0f64)));
	assert(isnan(modf64(-INF, PI)));
	assert(isnan(modf64(-INF, INF)));
	assert(isnan(modf64(-INF, NAN)));
	assert(modf64(-PI, -INF) == -PI);
	assert(isnan(modf64(-PI, 0f64)));
	assert(modf64(-PI, INF) == -PI);
	assert(isnan(modf64(-PI, NAN)));
	assert(modf64(-0f64, -INF) == -0f64);
	assert(isnan(modf64(-0f64, 0f64)));
	assert(modf64(-0f64, INF) == -0f64);
	assert(isnan(modf64(-0f64, NAN)));
	assert(modf64(0f64, -INF) == 0f64);
	assert(isnan(modf64(0f64, 0f64)));
	assert(modf64(0f64, INF) == 0f64);
	assert(isnan(modf64(0f64, NAN)));
	assert(modf64(PI, -INF) == PI);
	assert(isnan(modf64(PI, 0f64)));
	assert(modf64(PI, INF) == PI);
	assert(isnan(modf64(PI, NAN)));
	assert(isnan(modf64(INF, -INF)));
	assert(isnan(modf64(INF, -PI)));
	assert(isnan(modf64(INF, 0f64)));
	assert(isnan(modf64(INF, PI)));
	assert(isnan(modf64(INF, INF)));
	assert(isnan(modf64(INF, NAN)));
	assert(isnan(modf64(NAN, -INF)));
	assert(isnan(modf64(NAN, -PI)));
	assert(isnan(modf64(NAN, 0f64)));
	assert(isnan(modf64(NAN, PI)));
	assert(isnan(modf64(NAN, INF)));
	assert(isnan(modf64(NAN, NAN)));
	assert(modf64(5.9790119248836734e+200, 1.1258465975523544) ==
		0.6447968302508578);
};
