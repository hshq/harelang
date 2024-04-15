// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use math;
use time;
use time::chrono;

// The nominal units of the Gregorian chronology. Used for chronological
// arithmetic.
export type unit = enum int {
	ERA,
	YEAR,
	MONTH,
	WEEK,
	DAY,
	HOUR,
	MINUTE,
	SECOND,
	NANOSECOND,
};

// Calculates the [[period]] between two [[date]]s, from A to B.
// The returned period, provided to [[reckon]] along with A, will produce B,
// regardless of the [[calculus]] used. All the period's non-zero fields will
// have the same sign.
export fn pdiff(a: date, b: date) period = {
	let p = period { ... };

	if (chrono::compare(&a, &b) == 0) {
		return p;
	};

	let reverse = if (chrono::compare(&a, &b) > 0) true else false;
	if (reverse) {
		let tmp = a;
		a = b;
		b = tmp;
	};

	p.years = _year(&b) - _year(&a);

	p.months = _month(&b) - _month(&a);
	if (p.months < 0) {
		p.years -= 1;
		p.months += 12;
	};

	p.days = _day(&b) - _day(&a);
	let year = _year(&b);
	let month = _month(&b);
	let monthdays = calc_days_in_month(year, month);
	for (_day(&a) > monthdays || p.days < 0) {
		month -= 1;
		if (month == 0) {
			year -= 1;
			month = 12;
		};
		monthdays = calc_days_in_month(year, month);

		p.months -= 1;
		if (p.months < 0) {
			p.years -= 1;
			p.months += 12;
		};
		p.days += monthdays;
	};

	p.hours = _hour(&b) - _hour(&a);
	if (p.hours < 0) {
		p.days -= 1;
		p.hours += 24;
	};

	p.minutes = _minute(&b) - _minute(&a);
	if (p.minutes < 0) {
		p.hours -= 1;
		p.minutes += 60;
	};

	p.seconds = _second(&b) - _second(&a);
	if (p.seconds < 0) {
		p.minutes -= 1;
		p.seconds += 60;
	};

	p.nanoseconds = _nanosecond(&b) - _nanosecond(&a);
	if (p.nanoseconds < 0) {
		p.seconds -= 1;
		p.nanoseconds += 1000000000; // 10E9
	};

	return if (reverse) neg(p) else p;
};

// Calculates the nominal [[unit]] difference between two [[date]]s.
export fn unitdiff(a: date, b: date, u: unit) i64 = {
	switch (u) {
	case unit::ERA =>
		return era(&b) - era(&a);
	case unit::YEAR =>
		return pdiff(a, b).years;
	case unit::MONTH =>
		const d = pdiff(a, b);
		return d.years * 12 + d.months;
	case unit::WEEK =>
		return unitdiff(a, b, unit::DAY) / 7;
	case unit::DAY =>
		return chrono::daydate(&b) - chrono::daydate(&a);
	case unit::HOUR =>
		return unitdiff(a, b, unit::DAY) * 24 + pdiff(a, b).hours;
	case unit::MINUTE =>
		return unitdiff(a, b, unit::HOUR) * 60 + pdiff(a, b).minutes;
	case unit::SECOND =>
		return unitdiff(a, b, unit::MINUTE) * 60 + pdiff(a, b).seconds;
	case unit::NANOSECOND =>
		return unitdiff(a, b, unit::SECOND) * 1000000000 + pdiff(a, b).nanoseconds;
	};
};

// Truncates the given [[date]] at the provided nominal [[unit]].
// The [[zflag]] parameter affects the final result. Example:
//
// 	// On this day in Sao Paulo, a +1 hour jump occurs at 00:00.
// 	// The time range 00:00..00:59 is never observed.
// 	//
// 	// 2000-10-08 12:00:00.000000000 -0200 -02 America/Sao_Paulo
// 	let a = date::new(chrono::tz("America/Sao_Paulo")!, -2 * time::HOUR,
// 		2000, 10,  8, 12)!
// 	//
// 	// 2000-10-08 01:00:00.000000000 -0200 -02 America/Sao_Paulo
// 	let b = date::truncate(a, date::zflag::GAP_END, date::unit::DAY)!;
//
export fn truncate(d: date, zf: zflag, u: unit) (date | invalid | zfunresolved) = {
	switch (u) {
	case unit::ERA =>
		return new(d.loc, zf,
			1, 1, 1,
			0, 0, 0, 0,
		);
	case unit::YEAR =>
		return new(d.loc, zf,
			_year(&d), 1, 1,
			0, 0, 0, 0,
		);
	case unit::MONTH =>
		return new(d.loc, zf,
			_year(&d), _month(&d), 1,
			0, 0, 0, 0,
		);
	case unit::WEEK =>
		const dd = chrono::daydate(&d) - _weekday(&d);
		const ymd = calc_ymd(dd);
		return new(d.loc, zf,
			ymd.0, ymd.1, ymd.2,
			0, 0, 0, 0,
		);
	case unit::DAY =>
		return new(d.loc, zf,
			_year(&d), _month(&d), _day(&d),
			0, 0, 0, 0,
		);
	case unit::HOUR =>
		return new(d.loc, zf,
			_year(&d), _month(&d), _day(&d),
			_hour(&d), 0, 0, 0,
		);
	case unit::MINUTE =>
		return new(d.loc, zf,
			_year(&d), _month(&d), _day(&d),
			_hour(&d), _minute(&d), 0, 0,
		);
	case unit::SECOND =>
		return new(d.loc, zf,
			_year(&d), _month(&d), _day(&d),
			_hour(&d), _minute(&d), _second(&d), 0,
		);
	case unit::NANOSECOND =>
		return d;
	};
};

@test fn pdiff() void = {
	const cases = [
		(
			new(chrono::UTC, 0, 2021, 1, 15, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2022, 2, 16, 0, 0, 0, 0)!,
			period {
				years = 1,
				months = 1,
				days = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 1, 15, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2022, 3, 27, 0, 0, 0, 0)!,
			period {
				years = 1,
				months = 2,
				days = 12,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 1, 15, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2022, 3, 14, 0, 0, 0, 0)!,
			period {
				years = 1,
				months = 1,
				days = 27,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 1, 15, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2021, 1, 16, 0, 0, 0, 0)!,
			period {
				days = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 1, 15, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2021, 1, 16, 1, 3, 2, 4)!,
			period {
				days = 1,
				hours = 1,
				minutes = 3,
				seconds = 2,
				nanoseconds = 4,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 1, 15, 2, 3, 2, 2)!,
			new(chrono::UTC, 0, 2021, 1, 16, 1, 1, 2, 4)!,
			period {
				hours = 22,
				minutes = 58,
				nanoseconds = 2,
				...
			},
		),
		(
			new(chrono::UTC, 0,  500, 1, 1, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 3500, 1, 1, 0, 6, 0, 0)!,
			period {
				years = 3000,
				minutes = 6,
				...
			},
		),
		(
			new(chrono::UTC, 0, -500, 1, 1, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2500, 1, 1, 0, 6, 0, 0)!,
			period {
				years = 3000,
				minutes = 6,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2000, 1, 1, 0, 0, 0, 0)!,
			new(chrono::UTC, 0, 2000, 1, 1, 0, 6, 0, 999999999)!,
			period {
				minutes = 6,
				nanoseconds = 999999999,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2000, 1, 1, 0, 6, 0, 999999999)!,
			new(chrono::UTC, 0, 2000, 1, 1, 0, 6, 1, 0)!,
			period {
				nanoseconds = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, -4000, 1, 1, 0, 6, 0, 999999999)!,
			new(chrono::UTC, 0, 4000,  1, 1, 0, 6, 1, 0)!,
			period {
				years = 8000,
				nanoseconds = 1,
				...
			},
		),
	];
	for (let (da, db, expected) .. cases) {
		const actual = pdiff(da, db);
		assert(peq(actual, expected), "pdiff miscalculation");
	};
};

@test fn unitdiff() void = {
	const cases = [
		(
			new(chrono::UTC, 0,  1994,  8, 27,  11, 20,  1,         2)!,
			new(chrono::UTC, 0,  2022,  1,  5,  13, 53, 30,        20)!,
			(27, 328, 1427, 9993, 239834, 14390073, 863404409i64,
				(863404409i64 * time::SECOND) + 18),
		),
		(
			new(chrono::UTC, 0,  1994,  8, 27,  11, 20,  1,         0)!,
			new(chrono::UTC, 0,  1994,  8, 28,  11, 20,  1,         2)!,
			(0, 0, 0, 1, 24, 1440, 86400i64,
				(86400i64 * time::SECOND) + 2),
		),
		(
			new(chrono::UTC, 0,  1994,  8, 27,  11, 20,  1,         0)!,
			new(chrono::UTC, 0,  1994,  8, 27,  11, 20,  1,         0)!,
			(0, 0, 0, 0, 0, 0, 0i64, 0i64),
		),
		(
			new(chrono::UTC, 0,  -500,  1,  1,   0, 59,  1,         0)!,
			new(chrono::UTC, 0,  2000,  1,  1,  23,  1,  1,         0)!,
			(2500, 30000, 130443, 913106, 913106 * 24 + 22,
				(913106 * 24 + 22) * 60 + 2,
				((913106 * 24 + 22) * 60 + 2) * 60i64,
				(((913106 * 24 + 22) * 60 + 2) * 60i64 *
					time::SECOND)),
		),
	];
	for (let (da, db, expected) .. cases) {
		assert(unitdiff(da, db, unit::YEAR) == expected.0,
			"invalid diff_in_years() result");
		assert(unitdiff(da, db, unit::MONTH) == expected.1,
			"invalid diff_in_months() result");
		assert(unitdiff(da, db, unit::WEEK) == expected.2,
			"invalid diff_in_weeks() result");
		assert(unitdiff(da, db, unit::DAY) == expected.3,
			"invalid diff_in_days() result");
		assert(unitdiff(da, db, unit::HOUR) == expected.4,
			"invalid diff_in_hours() result");
		assert(unitdiff(da, db, unit::MINUTE) == expected.5,
			"invalid diff_in_minutes() result");
		assert(unitdiff(da, db, unit::SECOND) == expected.6,
			"invalid diff_in_seconds() result");
		assert(unitdiff(da, db, unit::NANOSECOND) == expected.7,
			"invalid diff_in_nanoseconds() result");
	};
};

@test fn truncate() void = {
	const d = new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 2)!;

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::ERA)!,
			&new(chrono::UTC, 0, 1, 1, 1, 0, 0, 0, 0)!)!,
		"invalid truncate() result 01");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::YEAR)!,
			&new(chrono::UTC, 0, 1994, 1, 1, 0, 0, 0, 0)!)!,
		"invalid truncate() result 02");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::MONTH)!,
			&new(chrono::UTC, 0, 1994, 8, 1, 0, 0, 0, 0)!)!,
		"invalid truncate() result 03");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::WEEK)!,
			&new(chrono::UTC, 0, 1994, 8, 22, 0, 0, 0, 0)!)!,
		"invalid truncate() result 04");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::DAY)!,
			&new(chrono::UTC, 0, 1994, 8, 27, 0, 0, 0, 0)!)!,
		"invalid truncate() result 05");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::HOUR)!,
			&new(chrono::UTC, 0, 1994, 8, 27, 11, 0, 0, 0)!)!,
		"invalid truncate() result 06");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::MINUTE)!,
			&new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 0, 0)!)!,
		"invalid truncate() result 07");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::SECOND)!,
			&new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 0)!)!,
		"invalid truncate() result 08");

	assert(chrono::simultaneous(
			&truncate(d, zflag::CONTIG, unit::NANOSECOND)!,
			&d)!,
		"invalid truncate() result 09");
};
