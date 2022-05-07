// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2021-2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use errors;
use time::chrono;

// Hare internally uses the Unix epoch (1970-01-01) for calendrical logic. Here
// we provide useful constant for working with the proleptic Gregorian calendar,
// as offsets from the Hare epoch.

// The Hare epoch of the Julian Day Number
export def EPOCHAL_JULIAN: i64 = -2440588;

// The Hare epoch of the Gregorian Common Era
export def EPOCHAL_GREGORIAN: i64 = -719164;

// Calculates whether a given year is a leap year.
export fn is_leap_year(y: int) bool = {
	return if (y % 4 != 0) false
	else if (y % 100 != 0) true
	else if (y % 400 != 0) false
	else true;
};

// Calculates whether a given (year, month, date) is valid
fn is_valid_ymd(y: int, m: int, d: int) bool = {
	return m >= 1 && m <= 12 && d >= 1 &&
		d <= calc_n_days_in_month(y, m);
};

// Returns whether a (year, yearday) date is valid
fn is_valid_yd(y: int, yd: int) bool = {
	return yd >= 1 && yd <= calc_n_days_in_year(y);
};

// Calculates the number of days in the given month of the given year
fn calc_n_days_in_month(y: int, m: int) int = {
	const days_per_month: [_]int = [
		31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	];
	if (m == 2) {
		if (is_leap_year(y)) {
			return 29;
		} else {
			return 28;
		};
	} else {
		return days_per_month[m - 1];
	};
};

// Calculates the number of days in a year
fn calc_n_days_in_year(y: int) int = {
	if (is_leap_year(y)) {
		return 366;
	} else {
		return 365;
	};
};

// Calculates the era, given a year
fn calc_era(y: int) int = {
	return if (y >= 0) {
		yield 1; // CE "Common Era"
	} else {
		yield 0; // BCE "Before Common Era"
	};
};

// Calculates the (year, month, day), given an epochal day
fn calc_ymd(e: chrono::epochal) (int, int, int) = {
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day#Julian_or_Gregorian_calendar_from_Julian_day_number
	//
	// Alternate methods of date calculation should be explored.
	const J = e - EPOCHAL_JULIAN;

	// TODO: substitute numbers where possible
	const b = 274277;
	const c = -38;
	const j = 1401;
	const m = 2;
	const n = 12;
	const p = 1461;
	const r = 4;
	const s = 153;
	const u = 5;
	const v = 3;
	const w = 2;
	const y = 4716;

	const f = J + j + (((4 * J + b) / 146097) * 3) / 4 + c;
	const a = r * f + v;
	const g = (a % p) / r;
	const h = u * g + w;

	const D = (h % s) / u + 1;
	const M = ((h / s + m) % n) + 1;
	const Y = (a / p) - y + (n + m - M) / n;

	return (Y: int, M: int, D: int);
};

// Calculates the day of a year, given a (year, month, day) date
fn calc_yearday(y: int, m: int, d: int) int = {
	const months_firsts: [_]int = [
		0, 31, 59,
		90, 120, 151,
		181, 212, 243,
		273, 304, 334,
	];

	if (m >= 3 && is_leap_year(y)) {
		return months_firsts[m - 1] + d + 1;
	} else {
		return months_firsts[m - 1] + d;
	};
};

// Calculates the ISO week-numbering year,
// given a (year, month, day, weekday) date
fn calc_isoweekyear(y: int, m: int, d: int, wd: int) int = {
	if (
		// if the date is within a week whose Thurday
		// belongs to the previous gregorian year
		m == 1 && (
			(d == 1 && (wd == 5 || wd == 6 || wd == 7))
			|| (d == 2 && (wd == 6 || wd == 7))
			|| (d == 3 && wd == 7)
		)
	) {
		return y - 1;
	} else if (
		// if the date is within a week whose Thurday
		// belongs to the next gregorian year
		m == 12 && (
			(d == 29 && wd == 1)
			|| (d == 30 && (wd == 1 || wd == 2))
			|| (d == 31 && (wd == 1 || wd == 2 || wd == 3))
		)
	) {
		return y + 1;
	} else {
		return y;
	};
};

// Calculates the ISO week, given a (year, week, weekday, yearday) date
fn calc_isoweek(y: int, w: int, wd: int, yd: int) int = {
	const jan1wd = (yd - wd + 7) % 7 + 1;

	const iw = if (jan1wd == 1) {
		yield w;
	} else if (jan1wd == 2 || jan1wd == 3 || jan1wd == 4) {
		yield w + 1;
	} else {
		yield if (w == 0) {
			yield if (jan1wd == 5) {
				yield 53;
			} else if (jan1wd == 6) {
				yield if (is_leap_year(y - 1)) {
					yield 53;
				} else {
					yield 52;
				};
			} else if (jan1wd == 7) {
				yield 52;
			} else {
				// all jan1wd values exhausted
				abort("Unreachable");
			};
		} else {
			yield w;
		};
	};
	return iw;
};

// Calculates the week within a Gregorian year [0..53],
// given a yearday and Gregorian weekday.
// All days in a new year before the year's first Monday belong to week 0.
fn calc_week(yd: int, wd: int) int = {
	return (yd + 7 - wd) / 7;
};

// Calculates the week within a Gregorian year [0..53],
// given a yearday and Gregorian weekday.
// All days in a new year before the year's first Sunday belong to week 0.
fn calc_week_starting_sunday(yd: int, wd: int) int = {
	return (yd + 6 - (wd % 7)) / 7;
};

// Calculates the weekday, given a epochal day,
// from Monday=1 to Sunday=7
fn calc_weekday(e: chrono::epochal) int = {
	const wd = ((e + 3) % 7 + 1): int;
	return if (wd > 0) wd else wd + 7;
};

// Calculates the zeroed weekday, given a weekday,
// from Monday=0 to Sunday=6
fn calc_zeroweekday(wd: int) int = {
	return wd - 1;
};

// Calculates the [[chrono::epochal]], given a (year, month, day) date
fn calc_epochal_from_ymd(y: int, m: int, d: int) (chrono::epochal | invalid) = {
	if (!is_valid_ymd(y, m, d)) {
		return invalid;
	};
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day
	//
	// Alternate methods of date calculation should be explored.
	const jdn = (
		(1461 * (y + 4800 + (m - 14) / 12)) / 4
		+ (367 * (m - 2 - 12 * ((m - 14) / 12))) / 12
		- (3 * ((y + 4900 + (m - 14) / 12) / 100)) / 4
		+ d
		- 32075
	);
	const e = jdn + EPOCHAL_JULIAN;
	return e;
};

// Calculates the [[chrono::epochal]], given a (year, week, weekday) date
fn calc_epochal_from_ywd(y: int, w: int, wd: int) (chrono::epochal | invalid) = {
	const jan1 = calc_epochal_from_ymd(y, 1, 1)?;
	const jan1_wd = calc_weekday(jan1);
	const yd = if (w == 0) {
		yield wd - jan1_wd + 1;
	} else {
		yield (7 - jan1_wd + 1) + (7 * (w - 1)) + wd;
	};
	const ymd = calc_ymd_from_yd(y, yd)?;
	return calc_epochal_from_ymd(ymd.0, ymd.1, ymd.2)?;
};

// Calculates a (year, month, day) date given a (year, yearday) date
fn calc_ymd_from_yd(y: int, yd: int) ((int, int, int) | invalid) = {
	if (!is_valid_yd(y, yd)) {
		return invalid;
	};
	let m: int = 1;
	let monthdays = calc_n_days_in_month(y, m);
	let d = yd;
	for (true) {
		if (m > 12) {
			return invalid;
		};
		if (d <= monthdays) {
			return (y, m, d);
		};
		d -= monthdays;
		m += 1;
		monthdays = calc_n_days_in_month(y, m);
	};
	return invalid;
};

// Calculates the [[chrono::epochal]], given a (year, yearday) date
fn calc_epochal_from_yd(y: int, yd: int) (chrono::epochal | invalid) = {
	const ymd = calc_ymd_from_yd(y, yd)?;
	return calc_epochal_from_ymd(ymd.0, ymd.1, ymd.2)?;
};

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
			assert(actual is invalid, "invalid date accepted");
		} else {
			assert(actual is chrono::epochal, "valid date not accepted");
			assert(actual as chrono::epochal == expect, "epochal miscalculation");
		};
	};
};

@test fn calc_ymd_from_yd() void = {
	const cases = [
		((-0768, 01, 01), 1),
		((-0768, 02, 05), 36),
		((-0001, 12, 31), 365),
		(( 0000, 01, 01), 1),
		(( 0000, 01, 02), 2),
		(( 0000, 12, 31), 366),
		(( 0001, 01, 01), 1),
		(( 0001, 01, 02), 2),
		(( 1965, 03, 23), 82),
		(( 1969, 12, 31), 365),
		(( 1970, 01, 01), 1),
		(( 1970, 01, 02), 2),
		(( 1999, 12, 31), 365),
		(( 2000, 01, 01), 1),
		(( 2000, 01, 02), 2),
		(( 2020, 01, 01), 1),
		(( 2022, 02, 28), 59),
		(( 2022, 03, 01), 60),
		(( 2023, 12, 31), 365),
		(( 2024, 02, 28), 59),
		(( 2024, 02, 29), 60),
		(( 2024, 03, 01), 61),
		(( 2024, 12, 12), 347),
		(( 2024, 12, 31), 366),
		(( 2038, 01, 18), 18),
		(( 2038, 01, 19), 19),
		(( 2038, 01, 20), 20),
		(( 2243, 10, 17), 290),
		(( 4707, 11, 28), 332),
		(( 4707, 11, 29), 333),
		((29349, 01, 25), 25),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const expected = cases[i].0;
		const yd = cases[i].1;
		const actual = calc_ymd_from_yd(expected.0, yd)!;
		assert(expected.0 == actual.0 &&
			expected.1 == actual.1 &&
			expected.2 == actual.2,
			"incorrect calc_ymd_from_yd() result");
	};
};

@test fn calc_epochal_from_ywd() void = {
	const cases = [
		((-0768, 00, 4), -1000034),
		((-0768, 05, 4), -999999),
		((-0001, 52, 5), -719529),
		(( 0000, 00, 6), -719528),
		(( 0000, 00, 7), -719527),
		(( 0000, 52, 7), -719163),
		(( 0001, 00, 1), -719162),
		(( 0001, 00, 2), -719161),
		(( 1965, 12, 2), -1745),
		(( 1969, 52, 3), -1),
		(( 1970, 00, 4), 0),
		(( 1970, 00, 5), 1),
		(( 1999, 52, 5), 10956),
		(( 2000, 00, 6), 10957),
		(( 2000, 00, 7), 10958),
		(( 2020, 00, 3), 18262),
		(( 2022, 09, 1), 19051),
		(( 2022, 09, 2), 19052),
		(( 2023, 51, 7), 19715),
		(( 2024, 08, 3), 19781),
		(( 2024, 08, 4), 19782),
		(( 2024, 08, 5), 19783),
		(( 2024, 49, 4), 20069),
		(( 2024, 52, 2), 20088),
		(( 2038, 03, 1), 24854),
		(( 2038, 03, 2), 24855),
		(( 2038, 03, 3), 24856),
		(( 2243, 41, 2), 99993),
		(( 4707, 47, 4), 999999),
		(( 4707, 47, 5), 1000000),
		((29349, 03, 6), 9999999),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const ywd = cases[i].0;
		const expected = cases[i].1;
		const actual = calc_epochal_from_ywd(ywd.0, ywd.1, ywd.2)!;
		assert(actual == expected,
			"incorrect calc_epochal_from_ywd() result");
	};
};

@test fn calc_epochal_from_yd() void = {
	const cases = [
		(-0768, 36,  -999999),
		(-0001, 365, -719529),
		( 0000, 1,   -719528),
		( 0000, 2,   -719527),
		( 0000, 366, -719163),
		( 0001, 1,   -719162),
		( 0001, 2,   -719161),
		( 1965, 82,  -1745  ),
		( 1969, 365, -1     ),
		( 1970, 1,   0      ),
		( 1970, 2,   1      ),
		( 1999, 365, 10956  ),
		( 2000, 1,   10957  ),
		( 2000, 2,   10958  ),
		( 2038, 18,  24854  ),
		( 2038, 19,  24855  ),
		( 2038, 20,  24856  ),
		( 2243, 290, 100000 ),
		( 4707, 332, 999999 ),
		( 4707, 333, 1000000),
		(29349, 25,  9999999),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const y = cases[i].0;
		const yd = cases[i].1;
		const expected = cases[i].2;
		const actual = calc_epochal_from_yd(y, yd)!;
		assert(expected == actual,
			"error in epochal calculation from yd");
	};
	assert(calc_epochal_from_yd(2020, 0) is invalid,
		"calc_epochal_from_yd() did not reject invalid yearday");
	assert(calc_epochal_from_yd(2020, 400) is invalid,
		"calc_epochal_from_yd() did not reject invalid yearday");
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
		((-0768, 02, 05),  036),
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
		(( 2020, 02, 12),  043),
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

@test fn calc_week() void = {
	const cases = [
		((1, 1), 1),
		((1, 2), 0),
		((1, 3), 0),
		((1, 4), 0),
		((1, 5), 0),
		((1, 6), 0),
		((1, 7), 0),
		((21, 2), 3),
		((61, 3), 9),
		((193, 5), 27),
		((229, 1), 33),
		((286, 4), 41),
		((341, 7), 48),
		((365, 6), 52),
		((366, 1), 53),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_week(params.0, params.1);
		assert(expect == actual, "week miscalculation");
	};
};

@test fn calc_week_starting_sunday() void = {
	const cases = [
		((1, 1), 0),
		((1, 2), 0),
		((1, 3), 0),
		((1, 4), 0),
		((1, 5), 0),
		((1, 6), 0),
		((1, 7), 1),
		((21, 2), 3),
		((61, 3), 9),
		((193, 5), 27),
		((229, 1), 33),
		((286, 4), 41),
		((341, 7), 49),
		((365, 6), 52),
		((366, 1), 53),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_week_starting_sunday(params.0, params.1);
		assert(expect == actual, "week miscalculation");
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
