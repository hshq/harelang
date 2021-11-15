use errors;
use time::chrono;

@test fn calc_epochal_from_ymd() void = {
	const cases = [
		((-0768, 02, 05),  -999999, false),
		((-0001, 12, 31),  -719529, false),
		(( 0000, 01, 01),  -719528, false),
		(( 0000, 01, 02),  -719527, false),
		(( 0000, 12, 31),  -719163, false),
		(( 0001, 01, 01),  -719162, false),
		(( 0001, 01, 02),  -719161, false),
		(( 1965, 03, 23),    -1745, false),
		(( 1969, 12, 31),       -1, false),
		(( 1970, 01, 01),        0, false),
		(( 1970, 01, 02),        1, false),
		(( 1999, 12, 31),    10956, false),
		(( 2000, 01, 01),    10957, false),
		(( 2000, 01, 02),    10958, false),
		(( 2038, 01, 18),    24854, false),
		(( 2038, 01, 19),    24855, false),
		(( 2038, 01, 20),    24856, false),
		(( 2243, 10, 17),   100000, false),
		(( 4707, 11, 28),   999999, false),
		(( 4707, 11, 29),  1000000, false),
		((29349, 01, 25),  9999999, false),

		(( 1970,-99,-99),  0, true),
		(( 1970, -9, -9),  0, true),
		(( 1970, -1, -1),  0, true),
		(( 1970, 00, 00),  0, true),
		(( 1970, 00, 01),  0, true),
		(( 1970, 01, 99),  0, true),
		(( 1970, 99, 99),  0, true),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const should_error = cases[i].2;
		const actual = calc_epochal_from_ymd(
			params.0, params.1, params.2,
		);

		if (should_error) {
			assert(actual is errors::invalid, "invalid date accepted");
		} else {
			assert(actual is chrono::epochal, "valid date not accepted");
			assert(actual as chrono::epochal == expect, "epochal miscalculation");
		};
	};
};

@test fn calc_ymd() void = {
	const cases = [
		(-999999,  (-0768, 02, 05)),
		(-719529,  (-0001, 12, 31)),
		(-719528,  ( 0000, 01, 01)),
		(-719527,  ( 0000, 01, 02)),
		(-719163,  ( 0000, 12, 31)),
		(-719162,  ( 0001, 01, 01)),
		(-719161,  ( 0001, 01, 02)),
		(  -1745,  ( 1965, 03, 23)),
		(     -1,  ( 1969, 12, 31)),
		(      0,  ( 1970, 01, 01)),
		(      1,  ( 1970, 01, 02)),
		(  10956,  ( 1999, 12, 31)),
		(  10957,  ( 2000, 01, 01)),
		(  10958,  ( 2000, 01, 02)),
		(  24854,  ( 2038, 01, 18)),
		(  24855,  ( 2038, 01, 19)),
		(  24856,  ( 2038, 01, 20)),
		( 100000,  ( 2243, 10, 17)),
		( 999999,  ( 4707, 11, 28)),
		(1000000,  ( 4707, 11, 29)),
		(9999999,  (29349, 01, 25)),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const paramt = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_ymd(paramt);
		assert(expect.0 == actual.0, "year mismatch");
		assert(expect.1 == actual.1, "month mismatch");
		assert(expect.2 == actual.2, "day mismatch");
	};
};

@test fn calc_yearday() void = {
	const cases = [
		((-0768, 02, 05),  037),
		((-0001, 12, 31),  365),
		(( 0000, 01, 01),  001),
		(( 0000, 01, 02),  002),
		(( 0000, 12, 31),  366),
		(( 0001, 01, 01),  001),
		(( 0001, 01, 02),  002),
		(( 1965, 03, 23),  082),
		(( 1969, 12, 31),  365),
		(( 1970, 01, 01),  001),
		(( 1970, 01, 02),  002),
		(( 1999, 12, 31),  365),
		(( 2000, 01, 01),  001),
		(( 2000, 01, 02),  002),
		(( 2038, 01, 18),  018),
		(( 2038, 01, 19),  019),
		(( 2038, 01, 20),  020),
		(( 2243, 10, 17),  290),
		(( 4707, 11, 28),  332),
		(( 4707, 11, 29),  333),
		((29349, 01, 25),  025),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_yearday(params.0, params.1, params.2);
		assert(expect == actual, "yearday miscalculation");
	};
};

@test fn calc_weekday() void = {
	const cases = [
		(-999999,  4), // -0768-02-05
		(-719529,  5), // -0001-12-31
		(-719528,  6), //  0000-01-01
		(-719527,  7), //  0000-01-02
		(-719163,  7), //  0000-12-31
		(-719162,  1), //  0001-01-01
		(-719161,  2), //  0001-01-02
		(  -1745,  2), //  1965-03-23
		(     -1,  3), //  1969-12-31
		(      0,  4), //  1970-01-01
		(      1,  5), //  1970-01-02
		(  10956,  5), //  1999-12-31
		(  10957,  6), //  2000-01-01
		(  10958,  7), //  2000-01-02
		(  24854,  1), //  2038-01-18
		(  24855,  2), //  2038-01-19
		(  24856,  3), //  2038-01-20
		( 100000,  2), //  2243-10-17
		( 999999,  4), //  4707-11-28
		(1000000,  5), //  4707-11-29
		(9999999,  6), // 29349-01-25
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const paramt = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_weekday(paramt);
		assert(expect == actual, "weekday miscalculation");
	};
};

