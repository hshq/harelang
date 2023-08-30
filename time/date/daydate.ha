// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2021-2022 Vlad-Stefan Harbuz <vlad@vladh.net>

// Hare internally uses the Unix epoch (1970-01-01) for calendrical logic. Here
// we provide useful constant for working with the astronomically numbered
// proleptic Gregorian calendar, as offsets from the Hare epoch.

// The Hare epoch of the Julian Day Number.
export def EPOCHAL_JULIAN: i64 = -2440588;

// The Hare epoch of the Gregorian Common Era.
export def EPOCHAL_GREGORIAN: i64 = -719164;

// Calculates whether a year is a leap year.
export fn isleapyear(y: int) bool = {
	return if (y % 4 != 0) false
	else if (y % 100 != 0) true
	else if (y % 400 != 0) false
	else true;
};

// Calculates whether a given year, month, and day-of-month, is a valid date.
fn is_valid_ymd(y: int, m: int, d: int) bool = {
	return m >= 1 && m <= 12 && d >= 1 &&
		d <= calc_month_daycnt(y, m);
};

// Calculates whether a given year, and day-of-year, is a valid date.
fn is_valid_yd(y: int, yd: int) bool = {
	return yd >= 1 && yd <= calc_year_daycnt(y);
};

// Calculates the number of days in the given month of the given year.
fn calc_month_daycnt(y: int, m: int) int = {
	const days_per_month: [_]int = [
		31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	];
	if (m == 2) {
		return if (isleapyear(y)) 29 else 28;
	} else {
		return days_per_month[m - 1];
	};
};

// Calculates the number of days in a given year.
fn calc_year_daycnt(y: int) int = {
	return if (isleapyear(y)) 366 else 365;
};

// Calculates the day-of-week of January 1st, given a year.
fn calc_janfirstweekday(y: int) int = {
	const y = (y % 400) + 400; // keep year > 0 (using Gregorian cycle)
	// Gauss' algorithm
	const wd = (5 * ((y - 1) % 4)
		+ 4 * ((y - 1) % 100)
		+ 6 * ((y - 1) % 400)
	) % 7;
	return wd;
};

// Calculates the era, given a year.
fn calc_era(y: int) int = {
	return if (y >= 0) {
		yield 1; // CE "Common Era"
	} else {
		yield 0; // BCE "Before Common Era"
	};
};

// Calculates the year, month, and day-of-month, given an epochal day.
fn calc_ymd(e: i64) (int, int, int) = {
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

// Calculates the day-of-year, given a year, month, and day-of-month.
fn calc_yearday(y: int, m: int, d: int) int = {
	const months_firsts: [_]int = [
		0, 31, 59,
		90, 120, 151,
		181, 212, 243,
		273, 304, 334,
	];

	if (m >= 3 && isleapyear(y)) {
		return months_firsts[m - 1] + d + 1;
	} else {
		return months_firsts[m - 1] + d;
	};
};

// Calculates the ISO week-numbering year,
// given a year, month, day-of-month, and day-of-week.
fn calc_isoweekyear(y: int, m: int, d: int, wd: int) int = {
	if (
		// if the date is within a week whose Thursday
		// belongs to the previous Gregorian year
		m == 1 && (
			(d == 1 && (wd == 4 || wd == 5 || wd == 6))
			|| (d == 2 && (wd == 5 || wd == 6))
			|| (d == 3 && wd == 6)
		)
	) {
		return y - 1;
	} else if (
		// if the date is within a week whose Thursday
		// belongs to the next Gregorian year
		m == 12 && (
			(d == 29 && wd == 0)
			|| (d == 30 && (wd == 0 || wd == 1))
			|| (d == 31 && (wd == 0 || wd == 1 || wd == 2))
		)
	) {
		return y + 1;
	} else {
		return y;
	};
};

// Calculates the ISO week,
// given a year, week, day-of-week, and day-of-year.
fn calc_isoweek(y: int, w: int) int = {
	switch (calc_janfirstweekday(y)) {
	case 0 =>
		return w;
	case 1, 2, 3 =>
		return w + 1;
	case 4 =>
		return if (w != 0) w else 53;
	case 5 =>
		return if (w != 0) w else {
			yield if (isleapyear(y - 1)) 53 else 52;
		};
	case 6 =>
		return if (w != 0) w else 52;
	case =>
		abort("Unreachable");
	};
};

// Calculates the week within a Gregorian year [0..53],
// given a day-of-year and day-of-week.
// All days in a year before the year's first Monday belong to week 0.
fn calc_week(yd: int, wd: int) int = {
	return (yd + 6 - wd) / 7;
};

// Calculates the week within a Gregorian year [0..53],
// given a day-of-year and day-of-week.
// All days in a year before the year's first Sunday belong to week 0.
fn calc_sundayweek(yd: int, wd: int) int = {
	return (yd + 6 - ((wd + 1) % 7)) / 7;
};

// Calculates the day-of-week, given a epochal day,
// from Monday=0 to Sunday=6.
fn calc_weekday(e: i64) int = {
	const wd = ((e + 3) % 7): int;
	return (wd + 7) % 7;
};

// Calculates the daydate,
// given a year, month, and day-of-month.
fn calc_daydate__ymd(y: int, m: int, d: int) (i64 | invalid) = {
	if (!is_valid_ymd(y, m, d)) {
		return invalid;
	};
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day
	//
	// TODO: Review, cite, verify, annotate.
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

// Calculates the daydate,
// given a year, week, and day-of-week.
fn calc_daydate__ywd(y: int, w: int, wd: int) (i64 | invalid) = {
	const jan1wd = calc_janfirstweekday(y);
	const yd = wd - jan1wd + 7 * w;
	return calc_daydate__yd(y, yd)?;
};

// Calculates the daydate,
// given a year and day-of-year.
fn calc_daydate__yd(y: int, yd: int) (i64 | invalid) = {
	if (yd < 1 || yd > calc_year_daycnt(y)) {
		return invalid;
	};
	return calc_daydate__ymd(y, 1, 1)? + yd - 1;
};

@test fn calc_daydate__ymd() void = {
	const cases = [
		(( -768,  2,  5),  -999999, false),
		((   -1, 12, 31),  -719529, false),
		((    0,  1,  1),  -719528, false),
		((    0,  1,  2),  -719527, false),
		((    0, 12, 31),  -719163, false),
		((    1,  1,  1),  -719162, false),
		((    1,  1,  2),  -719161, false),
		(( 1965,  3, 23),    -1745, false),
		(( 1969, 12, 31),       -1, false),
		(( 1970,  1,  1),        0, false),
		(( 1970,  1,  2),        1, false),
		(( 1999, 12, 31),    10956, false),
		(( 2000,  1,  1),    10957, false),
		(( 2000,  1,  2),    10958, false),
		(( 2038,  1, 18),    24854, false),
		(( 2038,  1, 19),    24855, false),
		(( 2038,  1, 20),    24856, false),
		(( 2243, 10, 17),   100000, false),
		(( 4707, 11, 28),   999999, false),
		(( 4707, 11, 29),  1000000, false),
		((29349,  1, 25),  9999999, false),

		(( 1970,-99,-99),  0, true),
		(( 1970, -9, -9),  0, true),
		(( 1970, -1, -1),  0, true),
		(( 1970,  0,  0),  0, true),
		(( 1970,  0,  1),  0, true),
		(( 1970,  1, 99),  0, true),
		(( 1970, 99, 99),  0, true),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const should_error = cases[i].2;
		const actual = calc_daydate__ymd(
			params.0, params.1, params.2,
		);

		if (should_error) {
			assert(actual is invalid, "invalid date accepted");
		} else {
			assert(actual is i64, "valid date not accepted");
			assert(actual as i64 == expect, "date miscalculation");
		};
	};
};

@test fn calc_daydate__ywd() void = {
	const cases = [
		(( -768,  0, 4), -1000034),
		(( -768,  5, 4), -999999),
		((   -1, 52, 5), -719529),
		((    0,  0, 6), -719528),
		((    0,  0, 7), -719527),
		((    0, 52, 7), -719163),
		((    1,  0, 1), -719162),
		((    1,  0, 2), -719161),
		(( 1965, 12, 2), -1745),
		(( 1969, 52, 3), -1),
		(( 1970,  0, 4), 0),
		(( 1970,  0, 5), 1),
		(( 1999, 52, 5), 10956),
		(( 2000,  0, 6), 10957),
		(( 2000,  0, 7), 10958),
		(( 2020,  0, 3), 18262),
		(( 2022,  9, 1), 19051),
		(( 2022,  9, 2), 19052),
		(( 2023, 51, 7), 19715),
		(( 2024,  8, 3), 19781),
		(( 2024,  8, 4), 19782),
		(( 2024,  8, 5), 19783),
		(( 2024, 49, 4), 20069),
		(( 2024, 52, 2), 20088),
		(( 2038,  3, 1), 24854),
		(( 2038,  3, 2), 24855),
		(( 2038,  3, 3), 24856),
		(( 2243, 41, 2), 99993),
		(( 4707, 47, 4), 999999),
		(( 4707, 47, 5), 1000000),
		((29349,  3, 6), 9999999),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const ywd = cases[i].0;
		const expected = cases[i].1;
		const actual = calc_daydate__ywd(ywd.0, ywd.1, ywd.2)!;
		assert(actual == expected,
			"incorrect calc_daydate__ywd() result");
	};
};

@test fn calc_daydate__yd() void = {
	const cases = [
		( -768, 36,  -999999),
		(   -1, 365, -719529),
		(    0, 1,   -719528),
		(    0, 2,   -719527),
		(    0, 366, -719163),
		(    1, 1,   -719162),
		(    1, 2,   -719161),
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
		const actual = calc_daydate__yd(y, yd)!;
		assert(expected == actual,
			"error in date calculation from yd");
	};
	assert(calc_daydate__yd(2020, 0) is invalid,
		"calc_daydate__yd() did not reject invalid yearday");
	assert(calc_daydate__yd(2020, 400) is invalid,
		"calc_daydate__yd() did not reject invalid yearday");
};

@test fn calc_ymd() void = {
	const cases = [
		(-999999, ( -768,  2,  5)),
		(-719529, (   -1, 12, 31)),
		(-719528, (    0,  1,  1)),
		(-719527, (    0,  1,  2)),
		(-719163, (    0, 12, 31)),
		(-719162, (    1,  1,  1)),
		(-719161, (    1,  1,  2)),
		(  -1745, ( 1965,  3, 23)),
		(     -1, ( 1969, 12, 31)),
		(      0, ( 1970,  1,  1)),
		(      1, ( 1970,  1,  2)),
		(  10956, ( 1999, 12, 31)),
		(  10957, ( 2000,  1,  1)),
		(  10958, ( 2000,  1,  2)),
		(  24854, ( 2038,  1, 18)),
		(  24855, ( 2038,  1, 19)),
		(  24856, ( 2038,  1, 20)),
		( 100000, ( 2243, 10, 17)),
		( 999999, ( 4707, 11, 28)),
		(1000000, ( 4707, 11, 29)),
		(9999999, (29349,  1, 25)),
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
		(( -768,  2,  5),  36),
		((   -1, 12, 31), 365),
		((    0,  1,  1),   1),
		((    0,  1,  2),   2),
		((    0, 12, 31), 366),
		((    1,  1,  1),   1),
		((    1,  1,  2),   2),
		(( 1965,  3, 23),  82),
		(( 1969, 12, 31), 365),
		(( 1970,  1,  1),   1),
		(( 1970,  1,  2),   2),
		(( 1999, 12, 31), 365),
		(( 2000,  1,  1),   1),
		(( 2000,  1,  2),   2),
		(( 2020,  2, 12),  43),
		(( 2038,  1, 18),  18),
		(( 2038,  1, 19),  19),
		(( 2038,  1, 20),  20),
		(( 2243, 10, 17), 290),
		(( 4707, 11, 28), 332),
		(( 4707, 11, 29), 333),
		((29349,  1, 25),  25),
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
		((  1, 0),  1),
		((  1, 1),  0),
		((  1, 2),  0),
		((  1, 3),  0),
		((  1, 4),  0),
		((  1, 5),  0),
		((  1, 6),  0),
		(( 21, 1),  3),
		(( 61, 2),  9),
		((193, 4), 27),
		((229, 0), 33),
		((286, 3), 41),
		((341, 6), 48),
		((365, 5), 52),
		((366, 0), 53),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_week(params.0, params.1);
		assert(expect == actual, "week miscalculation");
	};
};

@test fn calc_sundayweek() void = {
	const cases = [
		((  1, 0),  0),
		((  1, 1),  0),
		((  1, 2),  0),
		((  1, 3),  0),
		((  1, 4),  0),
		((  1, 5),  0),
		((  1, 6),  1),
		(( 21, 1),  3),
		(( 61, 2),  9),
		((193, 4), 27),
		((229, 0), 33),
		((286, 3), 41),
		((341, 6), 49),
		((365, 5), 52),
		((366, 0), 53),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const params = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_sundayweek(params.0, params.1);
		assert(expect == actual, "week miscalculation");
	};
};

@test fn calc_weekday() void = {
	const cases = [
		(-999999, 3), // -0768-02-05
		(-719529, 4), // -0001-12-31
		(-719528, 5), //  0000-01-01
		(-719527, 6), //  0000-01-02
		(-719163, 6), //  0000-12-31
		(-719162, 0), //  0001-01-01
		(-719161, 1), //  0001-01-02
		(  -1745, 1), //  1965-03-23
		(     -1, 2), //  1969-12-31
		(      0, 3), //  1970-01-01
		(      1, 4), //  1970-01-02
		(  10956, 4), //  1999-12-31
		(  10957, 5), //  2000-01-01
		(  10958, 6), //  2000-01-02
		(  24854, 0), //  2038-01-18
		(  24855, 1), //  2038-01-19
		(  24856, 2), //  2038-01-20
		( 100000, 1), //  2243-10-17
		( 999999, 3), //  4707-11-28
		(1000000, 4), //  4707-11-29
		(9999999, 5), // 29349-01-25
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const paramt = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_weekday(paramt);
		assert(expect == actual, "weekday miscalculation");
	};
};

@test fn calc_janfirstweekday() void = {
	const cases = [
	//	 year   weekday
		(1969,  2),
		(1970,  3),
		(1971,  4),
		(1972,  5),
		(1973,  0),
		(1974,  1),
		(1975,  2),
		(1976,  3),
		(1977,  5),
		(1978,  6),
		(1979,  0),
		(1980,  1),
		(1981,  3),
		(1982,  4),
		(1983,  5),
		(1984,  6),
		(1985,  1),
		(1986,  2),
		(1987,  3),
		(1988,  4),
		(1989,  6),
		(1990,  0),
		(1991,  1),
		(1992,  2),
		(1993,  4),
		(1994,  5),
		(1995,  6),
		(1996,  0),
		(1997,  2),
		(1998,  3),
		(1999,  4),
		(2000,  5),
		(2001,  0),
		(2002,  1),
		(2003,  2),
		(2004,  3),
		(2005,  5),
		(2006,  6),
		(2007,  0),
		(2008,  1),
		(2009,  3),
		(2010,  4),
		(2011,  5),
		(2012,  6),
		(2013,  1),
		(2014,  2),
		(2015,  3),
		(2016,  4),
		(2017,  6),
		(2018,  0),
		(2019,  1),
		(2020,  2),
		(2021,  4),
		(2022,  5),
		(2023,  6),
		(2024,  0),
		(2025,  2),
		(2026,  3),
		(2027,  4),
		(2028,  5),
		(2029,  0),
		(2030,  1),
		(2031,  2),
		(2032,  3),
		(2033,  5),
		(2034,  6),
		(2035,  0),
		(2036,  1),
		(2037,  3),
		(2038,  4),
		(2039,  5),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const paramt = cases[i].0;
		const expect = cases[i].1;
		const actual = calc_janfirstweekday(paramt);
		assert(expect == actual, "calc_janfirstweekday() miscalculation");
	};
};