// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use math;
use memio;

@test fn ftosf() void = {
	// These tests should pass for both f32 and f64.
	const tcs: [](f64, ffmt, (void | uint), fflags, str) = [
		// First test special values
		(1.0 / 0.0, ffmt::G, void, 0, "infinity"),
		(1.0 / 0.0, ffmt::G, void, fflags::SHOW_POS, "+infinity"),
		(-1.0 / 0.0, ffmt::F, void, 0, "-infinity"),
		(-1.0 / 0.0, ffmt::E, void, fflags::UPPERCASE, "-INFINITY"),
		(0.0 / 0.0, ffmt::G, void, 0, "nan"),
		(0.0 / 0.0, ffmt::E, void, fflags::UPPERCASE, "NAN"),

		// Then a million tests for zero.
		(0.0, ffmt::E, void, 0, "0e0"),
		(0.0, ffmt::E, void, fflags::SHOW_TWO_EXP_DIGITS, "0e00"),
		(0.0, ffmt::E, void, fflags::UPPER_EXP, "0E0"),
		(0.0, ffmt::E, void, fflags::SHOW_POS_EXP, "0e+0"),
		(0.0, ffmt::E, void, fflags::SHOW_POINT, "0.0e0"),
		(0.0, ffmt::F, void, 0, "0"),
		(0.0, ffmt::F, void, fflags::SHOW_POINT, "0.0"),
		(0.0, ffmt::G, void, 0, "0"),
		(-0.0, ffmt::G, void, fflags::SHOW_POS, "-0"),
		(0.0, ffmt::G, void, fflags::SHOW_POS, "+0"),
		(0.0, ffmt::G, void, fflags::SHOW_POINT, "0.0"),

		// ... e and f do not cut trailing zeros
		(0.0, ffmt::E, 0, 0, "0e0"),
		(0.0, ffmt::E, 1, 0, "0.0e0"),
		(0.0, ffmt::E, 2, 0, "0.00e0"),
		(0.0, ffmt::F, 0, 0, "0"),
		(0.0, ffmt::F, 1, 0, "0.0"),
		(0.0, ffmt::F, 2, 0, "0.00"),
		// ... g cuts trailing zeros
		(0.0, ffmt::G, 0, 0, "0"),
		(0.0, ffmt::G, 1, 0, "0"),
		(0.0, ffmt::G, 2, 0, "0"),

		// ... SHOW_POINT only changes precision 0
		(0.0, ffmt::E, 0, fflags::SHOW_POINT, "0.0e0"),
		(0.0, ffmt::E, 1, fflags::SHOW_POINT, "0.0e0"),
		(0.0, ffmt::E, 2, fflags::SHOW_POINT, "0.00e0"),
		(0.0, ffmt::F, 0, fflags::SHOW_POINT, "0.0"),
		(0.0, ffmt::F, 1, fflags::SHOW_POINT, "0.0"),
		(0.0, ffmt::F, 2, fflags::SHOW_POINT, "0.00"),
		// ... g with SHOW_POINT only has the one extra 0
		(0.0, ffmt::G, 0, fflags::SHOW_POINT, "0.0"),
		(0.0, ffmt::G, 1, fflags::SHOW_POINT, "0.0"),
		(0.0, ffmt::G, 2, fflags::SHOW_POINT, "0.0"),

		// Now we can test actual numbers.
		(10.0, ffmt::F, void, 0, "10"),
		(1.0, ffmt::F, void, 0, "1"),
		(1.1, ffmt::F, void, 0, "1.1"),
		(13.37, ffmt::G, void, 0, "13.37"),
		(0.3, ffmt::F, void, 0, "0.3"),
		(0.0031415, ffmt::F, void, 0, "0.0031415"),
		(-6345.972, ffmt::F, void, 0, "-6345.972"),
		(1.414, ffmt::F, void, 0, "1.414"),
		(1000000.0e9, ffmt::F, void, 0, "1000000000000000"),
		(10.0, ffmt::E, void, 0, "1e1"),
		(10.0, ffmt::E, void, fflags::SHOW_TWO_EXP_DIGITS, "1e01"),
		(10.0, ffmt::E, void, fflags::UPPER_EXP, "1E1"),
		(10.0, ffmt::E, void, fflags::SHOW_POS_EXP, "1e+1"),
		(0.1, ffmt::E, void, fflags::SHOW_POS_EXP, "1e-1"),
		(1.0, ffmt::E, void, 0, "1e0"),
		(0.3, ffmt::E, void, 0, "3e-1"),
		(0.0031415, ffmt::E, void, 0, "3.1415e-3"),
		(0.12345, ffmt::E, void, 0, "1.2345e-1"),

		// ... g is shortest
		(12345.0, ffmt::G, void, 0, "12345"),
		(10000.0, ffmt::G, void, 0, "1e4"),
		(11000.0, ffmt::G, void, 0, "1.1e4"),
		(1000.0, ffmt::G, void, 0, "1e3"),
		(1100.0, ffmt::G, void, 0, "1100"),
		(100.0, ffmt::G, void, 0, "100"),
		(10.0, ffmt::G, void, 0, "10"),
		(1.0, ffmt::G, void, 0, "1"),
		(0.1, ffmt::G, void, 0, "0.1"),
		(0.01, ffmt::G, void, 0, "0.01"),
		(0.011, ffmt::G, void, 0, "0.011"),
		(0.001, ffmt::G, void, 0, "1e-3"), // one shorter than f
		(0.0011, ffmt::G, void, 0, "1.1e-3"), // same length as f
		(0.0001, ffmt::G, void, 0, "1e-4"),

		// ... fixed precision stuff
		(0.5, ffmt::F, 0, 0, "0"),
		(1.0 / 3.0, ffmt::F, 2, 0, "0.33"),
		(1.0 / 3.0, ffmt::F, 1, 0, "0.3"),
		(1.0 / 3.0, ffmt::F, 0, 0, "0"),
		(1.0 / 3.0, ffmt::F, 0, fflags::SHOW_POINT, "0.3"),
		(2.0 / 3.0, ffmt::F, 2, 0, "0.67"),
		(2.0 / 3.0, ffmt::F, 1, 0, "0.7"),
		(2.0 / 3.0, ffmt::F, 0, 0, "1"),
		(2.0 / 3.0, ffmt::F, 0, fflags::SHOW_POINT, "0.7"),
		(2.0 / 30.0, ffmt::F, 5, 0, "0.06667"),
		(2.0 / 30.0, ffmt::F, 2, 0, "0.07"),
		(2.0 / 30.0, ffmt::F, 1, 0, "0.1"),
		(2.0 / 30.0, ffmt::F, 1, fflags::SHOW_POINT, "0.1"),
		(200.0 / 3.0, ffmt::F, 4, 0, "66.6667"),
		(100.0 / 3.0, ffmt::F, 4, 0, "33.3333"),
		(100.0 / 3.0, ffmt::F, 0, 0, "33"),
		(100.0 / 3.0, ffmt::F, 0, fflags::SHOW_POINT, "33.3"),
		(0.00001, ffmt::F, 1, 0, "0.0"),
		(0.001, ffmt::F, 2, 0, "0.00"),
		(0.006, ffmt::F, 2, 0, "0.01"),
		(0.001, ffmt::F, 6, 0, "0.001000"),
		(1.0, ffmt::F, 6, 0, "1.000000"),
		(100.0, ffmt::F, 6, 0, "100.000000"),

		// ... scientific notation stuff
		(460.0, ffmt::E, 2, 0, "4.60e2"),
		(1.0 / 3.0, ffmt::E, 2, 0, "3.33e-1"),
		(1.0 / 3.0, ffmt::E, 1, 0, "3.3e-1"),
		(1.0 / 3.0, ffmt::E, 0, 0, "3e-1"),
		(1.0 / 3.0, ffmt::E, 0, fflags::SHOW_POINT, "3.3e-1"),
		(2.0 / 3.0, ffmt::E, 2, 0, "6.67e-1"),
		(2.0 / 3.0, ffmt::E, 1, 0, "6.7e-1"),
		(2.0 / 3.0, ffmt::E, 0, 0, "7e-1"),
		(2.0 / 3.0, ffmt::E, 0, fflags::SHOW_POINT, "6.7e-1"),
		(2.0 / 30.0, ffmt::E, 5, 0, "6.66667e-2"),
		(2.0 / 30.0, ffmt::E, 2, 0, "6.67e-2"),
		(2.0 / 30.0, ffmt::E, 0, 0, "7e-2"),
		(2.0 / 30.0, ffmt::E, 0, fflags::SHOW_POINT, "6.7e-2"),
		(200.0 / 3.0, ffmt::E, 5, 0, "6.66667e1"),
		(100.0 / 3.0, ffmt::E, 5, 0, "3.33333e1"),
		(100.0 / 3.0, ffmt::E, 0, 0, "3e1"),
		(100.0 / 3.0, ffmt::E, 0, fflags::SHOW_POINT, "3.3e1"),
		(0.001, ffmt::E, 2, 0, "1.00e-3"),
		(1.0, ffmt::E, 6, 0, "1.000000e0"),
		(100.0, ffmt::E, 6, 0, "1.000000e2"),

		// ... and G. The behavior with SHOW_POINT is gnarly.
		(1.0 / 3.0, ffmt::G, 2, 0, "0.33"),
		(1.0 / 3.0, ffmt::G, 0, 0, "0.3"),
		(0.01, ffmt::G, void, fflags::SHOW_POINT, "0.01"),
		(1.0, ffmt::G, void, fflags::SHOW_POINT, "1.0"),
		(0.0001, ffmt::G, 0, 0, "1e-4"),
		(0.001, ffmt::G, 0, 0, "1e-3"),
		(0.00123, ffmt::G, 2, 0, "1.2e-3"),
		(0.01, ffmt::G, 5, 0, "0.01"), // trim trailing zeros
		(0.1, ffmt::G, 5, 0, "0.1"),
		(1.0, ffmt::G, 0, 0, "1"),
		(10.0, ffmt::G, 0, 0, "10"),
		(120.0, ffmt::G, 2, 0, "120"),
		(12000.0, ffmt::G, 2, 0, "1.2e4"),
		(0.0001, ffmt::G, 0, fflags::SHOW_POINT, "1.0e-4"),
		(0.001, ffmt::G, 0, fflags::SHOW_POINT, "1.0e-3"),
		(0.01, ffmt::G, 0, fflags::SHOW_POINT, "0.01"),
		(0.1, ffmt::G, 0, fflags::SHOW_POINT, "0.1"),
		(1.0, ffmt::G, 0, fflags::SHOW_POINT, "1.0"),
		(10.0, ffmt::G, 0, fflags::SHOW_POINT, "10.0"),
		(100.0, ffmt::G, 0, fflags::SHOW_POINT, "100.0"),
		(1000.0, ffmt::G, 0, fflags::SHOW_POINT, "1.0e3"),
		(0.0123, ffmt::G, 2, fflags::SHOW_POINT, "0.012"),
		(0.0123, ffmt::G, 5, fflags::SHOW_POINT, "0.0123"),
	];
	const stream = memio::dynamic();
	defer io::close(&stream)!;
	for (let i = 0z; i < len(tcs); i += 1) {
		const z64 = fftosf(&stream, tcs[i].0, tcs[i].1,
			tcs[i].2, tcs[i].3)!;
		const res64 = memio::string(&stream)!;
		assert(len(res64) == z64);
		assert(res64 == tcs[i].4, res64);
		if (tcs[i].2 is void) {
			// void precision should guarantee that it parses back
			// to the original number.
			const back = stof64(res64)!;
			assert(math::isnan(back) == math::isnan(tcs[i].0));
			if (!math::isnan(back)) assert(back == tcs[i].0);
		};

		memio::reset(&stream);
		const z32 = fftosf(&stream, tcs[i].0: f32, tcs[i].1,
			tcs[i].2, tcs[i].3)!;
		const res32 = memio::string(&stream)!;
		assert(len(res32) == z32);
		assert(res32 == tcs[i].4);
		if (tcs[i].2 is void) {
			const back = stof32(res32)!;
			assert(math::isnan(back) == math::isnan(tcs[i].0));
			if (!math::isnan(back)) assert(back == tcs[i].0: f32);
		};
		memio::reset(&stream);
	};
	// These tests will only pass for f64
	const tcsf64: [](f64, ffmt, (void | uint), fflags, str) = [
		(9007199254740991.0, ffmt::F, void, 0, "9007199254740991"),
		(90071992547409915.0, ffmt::F, void, 0, "90071992547409920"),
		(90071992547409925.0, ffmt::F, void, 0, "90071992547409920"),
		(math::F64_MIN, ffmt::E, void, 0, "5e-324"),
		(math::F64_MIN, ffmt::E, void, fflags::SHOW_TWO_EXP_DIGITS, "5e-324"),
		(-math::F64_MIN, ffmt::E, void, 0, "-5e-324"),
		(math::F64_MIN_NORMAL, ffmt::E, void, 0, "2.2250738585072014e-308"),
		(math::F64_MAX_NORMAL, ffmt::E, void, 0, "1.7976931348623157e308"),
		(math::F64_MIN, ffmt::E, 2, 0, "4.94e-324"),
		(math::F64_MIN_NORMAL, ffmt::E, 0, 0, "2e-308"),
		(math::F64_MAX_NORMAL, ffmt::E, 3, 0, "1.798e308"),
	];
	for (let i = 0z; i < len(tcsf64); i += 1) {
		const z64 = fftosf(&stream, tcsf64[i].0, tcsf64[i].1,
			tcsf64[i].2, tcsf64[i].3)!;
		const res64 = memio::string(&stream)!;
		assert(len(res64) == z64);
		assert(res64 == tcsf64[i].4);
		memio::reset(&stream);
	};
	// These tests will only pass for f32
	const tcsf32: [](f32, ffmt, (void | uint), fflags, str) = [
		(math::F32_MIN, ffmt::G, void, 0, "1e-45"),
		(math::F32_MIN_NORMAL, ffmt::G, void, 0, "1.1754944e-38"),
		(math::F32_MAX_NORMAL, ffmt::G, void, 0, "3.4028235e38"),
	];
	for (let i = 0z; i < len(tcsf32); i += 1) {
		const z32 = fftosf(&stream, tcsf32[i].0, tcsf32[i].1,
			tcsf32[i].2, tcsf32[i].3)!;
		const res32 = memio::string(&stream)!;
		assert(len(res32) == z32);
		assert(res32 == tcsf32[i].4);
		memio::reset(&stream);
	};
	// Just make sure we can generate big numbers without breaking anything.
	const tcslen: [](f64, ffmt, (void | uint), fflags, size) = [
		(9007199254740991.0, ffmt::F, void, 0, 16),
		(-math::F64_MIN, ffmt::E, 100, 0, 108),
		(1.0, ffmt::F, 1000, 0, 1002),
		(2.22507385850720088902458687609E-308, ffmt::F, 1000, 0, 1002),
	];
	for (let i = 0z; i < len(tcslen); i += 1) {
		const z64 = fftosf(&stream, tcslen[i].0, tcslen[i].1,
			tcslen[i].2, tcslen[i].3)!;
		const res64 = memio::string(&stream)!;
		assert(len(res64) == z64);
		assert(len(res64) == tcslen[i].4);
		memio::reset(&stream);
	};
	assert(f64tos(13.37) == "13.37");
};
