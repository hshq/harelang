// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021-2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use fmt;
use math;
use time;
use time::chrono;

// Represents a span of time in the Gregorian chronology, using nominal units of
// time. Used for datetime arithmetic.
export type period = struct {
	eras: int,
	years: int,

	// Can be 28, 29, 30, or 31 days long
	months: int,

	// Weeks start on Monday
	weeks: int,

	days: int,
	hours: int,
	minutes: int,
	seconds: int,
	nanoseconds: i64,
};

// Specifies the behaviour of calendar arithmetic.
export type calculus = enum int {
	// Units are added in the order of largest (years) to smallest
	// (nanoseconds). If the resulting date does not exist, the first extant
	// date previous to the initial result is returned.
	DEFAULT,
};
// TODO: ^ Expand this

// The nominal units of the Gregorian chronology. Used for datetime arithmetic.
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

// Returns true if two [[datetime]]s are equivalent.
//
// Equivalence means they represent the same moment in time, regardless of their
// locality or observed chronological values.
export fn eq(a: datetime, b: datetime) bool = {
	return a.date == b.date && a.time == b.time;
};

// Returns true if [[datetime]] "a" succeeds [[datetime]] "b".
//
// Temporal order is evaluated in a universal frame of reference, regardless of
// their locality or observed chronological values.
export fn after(a: datetime, b: datetime) bool = {
	return !eq(a, b) &&
		(a.date > b.date || a.date == b.date && a.time > b.time);
};

// Returns true if [[datetime]] "a" precedes [[datetime]] "b".
//
// Temporal order is evaluated in a universal frame of reference, regardless of
// their locality or observed chronological values.
export fn before(a: datetime, b: datetime) bool = {
	return !eq(a, b) && !after(a, b);
};

// Calculates the [[period]] between two [[datetime]]s.
export fn diff(a: datetime, b: datetime) period = {
	let res = period { ... };
	if (eq(a, b)) {
		return res;
	};
	if (after(b, a)) {
		const tmp = a;
		a = b;
		b = tmp;
	};

	res.years = year(&a) - year(&b);

	res.months = month(&a) - month(&b);
	if (res.months < 0) {
		res.years -= 1;
		res.months = 12 + res.months;
	};

	res.days = day(&a) - day(&b);
	if (res.days < 0) {
		let prev_month_year = year(&a);
		let prev_month = month(&a) - 1;
		if (prev_month == 0) {
			prev_month_year -= 1;
			prev_month = 12;
		};
		const n_days_in_prev_month = calc_n_days_in_month(
			prev_month_year, prev_month);
		res.months -= 1;
		res.days = n_days_in_prev_month + res.days;
	};

	res.hours = hour(&a) - hour(&b);
	if (res.hours < 0) {
		res.days -= 1;
		res.hours = 24 + res.hours;
	};

	res.minutes = minute(&a) - minute(&b);
	if (res.minutes < 0) {
		res.hours -= 1;
		res.minutes = 60 + res.minutes;
	};

	res.seconds = second(&a) - second(&b);
	if (res.seconds < 0) {
		res.minutes -= 1;
		res.seconds = 60 + res.seconds;
	};

	res.nanoseconds = nanosecond(&a) - nanosecond(&b);
	if (res.nanoseconds < 0) {
		res.seconds -= 1;
		res.nanoseconds = time::SECOND + res.nanoseconds;
	};

	return res;
};

// Calculates the difference between two [[datetime]]s using the given nominal
// [[unit]], truncating towards zero.
export fn unitdiff(a: datetime, b: datetime, u: unit) i64 = {
	return switch (u) {
	case unit::ERA =>
		yield math::absi(era(&a) - era(&b)): i64;
	case unit::YEAR =>
		yield diff(a, b).years;
	case unit::MONTH =>
		const full_diff = diff(a, b);
		yield full_diff.years * 12 + full_diff.months;
	case unit::WEEK =>
		yield unitdiff(a, b, unit::DAY) / 7;
	case unit::DAY =>
		yield math::absi(a.date - b.date): int;
	case unit::HOUR =>
		const full_diff = diff(a, b);
		yield (unitdiff(a, b, unit::DAY) * 24) + full_diff.hours;
	case unit::MINUTE =>
		const full_diff = diff(a, b);
		yield unitdiff(a, b, unit::HOUR) * 60 + full_diff.minutes;
	case unit::SECOND =>
		const full_diff = diff(a, b);
		yield unitdiff(a, b, unit::MINUTE) * 60 + full_diff.seconds;
	case unit::NANOSECOND =>
		const full_diff = diff(a, b);
		yield unitdiff(a, b, unit::SECOND) * time::SECOND +
			full_diff.nanoseconds;
	};
};

// Returns true if two [[period]]s are numerically equal.
export fn period_eq(a: period, b: period) bool = {
	return a.eras == b.eras &&
		a.years == b.years &&
		a.months == b.months &&
		a.weeks == b.weeks &&
		a.days == b.days &&
		a.hours == b.hours &&
		a.minutes == b.minutes &&
		a.seconds == b.seconds &&
		a.nanoseconds == b.nanoseconds;
};

// Truncates the given [[datetime]] at the provided nominal [[unit]].
//
// For example, truncating to the nearest [[unit::MONTH]] will set the day,
// hour, minute, seconds, and nanoseconds fields to their minimum values.
export fn truncate(dt: datetime, u: unit) datetime = {
	// TODO: Replace all of the 0s for the zoffset with the actual
	// zoffset once the API is solidified a bit
	return switch (u) {
	case unit::ERA =>
		yield new(dt.loc, 0,
			1, 1, 1,
			0, 0, 0, 0,
		)!;
	case unit::YEAR =>
		yield new(dt.loc, 0,
			year(&dt), 1, 1,
			0, 0, 0, 0,
		)!;
	case unit::MONTH =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), 1,
			0, 0, 0, 0,
		)!;
	case unit::WEEK =>
		const date = dt.date - (weekday(&dt) - 1);
		const ymd = calc_ymd(date);
		yield new(dt.loc, 0,
			ymd.0, ymd.1, ymd.2,
			0, 0, 0, 0,
		)!;
	case unit::DAY =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			0, 0, 0, 0,
		)!;
	case unit::HOUR =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), 0, 0, 0,
		)!;
	case unit::MINUTE =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), minute(&dt), 0, 0,
		)!;
	case unit::SECOND =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), minute(&dt), second(&dt), 0,
		)!;
	case unit::NANOSECOND =>
		yield dt;
	};
};

// Given a [[datetime]] and a [[period]], "hops" to the minimum value of each
// field (years, months, days, etc) plus or minus an offset, and returns a new
// datetime. This can be used, for example, to find the start of last year.
//
// Consults each period's fields from most to least significant (from years to
// nanoseconds).
//
// If a period's field's value N is zero, it's a no-op. Otherwise, hop will
// reckon to the Nth inter-period point from where last reckoned. This repeats
// until all the given period's fields are exhausted.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::hop(dt, datetime::period {
// 		years  = 22, // produces 2021-01-01 00:00:00
// 		months = -1, // produces 2020-11-01 00:00:00
// 		days   = -4, // produces 2020-10-27 00:00:00
// 	});
//
export fn hop(dt: datetime, pp: period...) datetime = {
	let new_dt = dt;
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];

		if (p.years != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { years = p.years, ... });
			new_dt = truncate(dt_inc, unit::YEAR);
		};
		if (p.months != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { months = p.months, ... });
			new_dt = truncate(dt_inc, unit::MONTH);
		};
		if (p.weeks != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { weeks = p.weeks, ... });
			new_dt = truncate(dt_inc, unit::WEEK);
		};
		if (p.days != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { days = p.days, ... });
			new_dt = truncate(dt_inc, unit::DAY);
		};
		if (p.hours != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { hours = p.hours, ... });
			new_dt = truncate(dt_inc, unit::HOUR);
		};
		if (p.minutes != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { minutes = p.minutes, ... });
			new_dt = truncate(dt_inc, unit::MINUTE);
		};
		if (p.seconds != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { seconds = p.seconds, ... });
			new_dt = truncate(dt_inc, unit::SECOND);
		};
		if (p.nanoseconds != 0) {
			new_dt = add(new_dt, calculus::DEFAULT,
				period { nanoseconds = p.nanoseconds, ... });
		};
	};
	return new_dt;
};

// Adds a period of time to a datetime, most significant units first. Conserves
// relative distance from cyclical points on the calendar when possible. This
// can be used, for example, to find the date one year from now.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::add(dt, datetime::calculus::DEFAULT, datetime::period {
// 		years  = 22, // 2021-05-13 12:30:45
// 		months = -1, // 2021-04-13 12:30:45
// 		days   = -4, // 2020-04-09 12:30:45
// 	});
//
export fn add(dt: datetime, flag: calculus, pp: period...) datetime = {
	// TODO: Use [[builder]] to simplify some code.
	let d_year = year(&dt);
	let d_month = month(&dt);
	let d_day = day(&dt);
	let d_hour = hour(&dt);
	let d_minute = minute(&dt);
	let d_second = second(&dt);
	let d_nanosecond = ((nanosecond(&dt)): i64);
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];

		let latest_date = dt.date;

		if (p.years != 0) {
			d_year += p.years;
		};
		if (p.months != 0) {
			d_month += p.months;
		};
		if (d_month > 12) {
			d_year += (d_month - 1) / 12;
			d_month = d_month % 12;
		};
		if (d_month < 1) {
			d_year -= (12 + -(d_month - 1)) / 12;
			d_month = 12 - (-d_month % 12);
		};
		const n_days_in_month = calc_n_days_in_month(d_year, d_month);
		if (d_day > n_days_in_month) {
			d_day = n_days_in_month;
		};

		if (p.weeks != 0) {
			p.days += p.weeks * 7;
		};
		latest_date = calc_date_from_ymd(
			d_year, d_month, d_day)!;
		if (p.days != 0) {
			const new_ymd = calc_ymd(latest_date + p.days);
			d_year = new_ymd.0;
			d_month = new_ymd.1;
			d_day = new_ymd.2;
			latest_date = calc_date_from_ymd(
				d_year, d_month, d_day)!;
		};

		if (p.hours != 0) {
			p.nanoseconds += p.hours * time::HOUR;
		};
		if (p.minutes != 0) {
			p.nanoseconds += p.minutes * time::MINUTE;
		};
		if (p.seconds != 0) {
			p.nanoseconds += p.seconds * time::SECOND;
		};
		if (p.nanoseconds != 0) {
			const ns_in_day = 24 * time::HOUR;
			let overflowed_days = 0;

			if (math::absi(p.nanoseconds): i64 > ns_in_day) {
				overflowed_days +=
					((p.nanoseconds / ns_in_day): int);
				p.nanoseconds %= ns_in_day;
			};

			let new_time = dt.time + p.nanoseconds;

			if (new_time >= ns_in_day) {
				overflowed_days += 1;
				new_time -= ns_in_day;
			} else if (new_time < 0) {
				overflowed_days -= 1;
				new_time += ns_in_day;
			};

			if (overflowed_days != 0) {
				const new_date = latest_date +
					overflowed_days;
				const new_ymd = calc_ymd(new_date);
				d_year = new_ymd.0;
				d_month = new_ymd.1;
				d_day = new_ymd.2;
			};
			const new_hmsn = calc_hmsn(new_time);
			d_hour = new_hmsn.0;
			d_minute = new_hmsn.1;
			d_second = new_hmsn.2;
			d_nanosecond = new_hmsn.3;
		};
	};
	// TODO: Add zoffset back in here once API is settled
	return new(dt.loc, 0,
		d_year, d_month, d_day, d_hour, d_minute, d_second, d_nanosecond: int,
	)!;
};

// Subtracts a calendrical period of time to a datetime, most significant units
// first. Conserves relative distance from cyclical points on the calendar when
// possible.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::subtract(dt, datetime::calculus::DEFAULT, datetime::period {
// 		years  = 22, // 1977-05-13 12:30:45
// 		months = -1, // 1977-06-13 12:30:45
// 		days   = -4, // 1977-06-17 12:30:45
// 	});
//
export fn sub(dt: datetime, flag: calculus, pp: period...) datetime = {
	for (let i = 0z; i < len(pp); i += 1) {
		pp[i].eras *= -1;
		pp[i].years *= -1;
		pp[i].months *= -1;
		pp[i].weeks *= -1;
		pp[i].days *= -1;
		pp[i].minutes *= -1;
		pp[i].seconds *= -1;
		pp[i].nanoseconds *= -1;
	};
	return add(dt, flag, pp...);
};

@test fn eq() void = {
	const dt = new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 0)!;
	const cases = [
		((-768, 1,  1,  3, 14,  7,    0), false),
		((   1, 1,  1, 14,  0,  0, 1234), false),
		((2022, 2,  4,  3, 14,  7,    0), true),
		((2022, 2,  4,  3, 14,  7,    1), false),
		((2038, 1, 19,  3, 14,  7,    0), false),
		((5555, 5,  5,  5, 55, 55, 5555), false),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const c = cases[i].0;
		const expected = cases[i].1;
		const case_dt = new(chrono::UTC, 0,
			c.0, c.1, c.2, c.3, c.4, c.5, c.6)!;
		assert(eq(dt, case_dt) == expected,
			"equality comparison failed");
	};
};

@test fn after() void = {
	const dt = new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 0)!;
	const cases = [
		((-768, 1,  1,  3, 14,  7,    0), false),
		((   1, 1,  1, 14,  0,  0, 1234), false),
		((2020, 2,  4,  3, 14,  7,    1), false),
		((2022, 2,  4,  3, 14,  7,    0), false),
		((2022, 2,  4,  4,  1,  1,    0), true),
		((2038, 1, 19,  3, 14,  7,    0), true),
		((5555, 5,  5,  5, 55, 55, 5555), true),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const c = cases[i].0;
		const expected = cases[i].1;
		const case_dt = new(chrono::UTC, 0,
			c.0, c.1, c.2, c.3, c.4, c.5, c.6)!;
		assert(after(case_dt, dt) == expected,
			"incorrect date ordering in after()");
	};
};

@test fn before() void = {
	const dt = new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 0)!;
	const cases = [
		((-768, 1,  1,  3, 14,  7,    0), true),
		((   1, 1,  1, 14,  0,  0, 1234), true),
		((2020, 2,  4,  3, 14,  7,    1), true),
		((2022, 2,  4,  3, 14,  7,    0), false),
		((2022, 2,  4,  4,  1,  1,    0), false),
		((2038, 1, 19,  3, 14,  7,    0), false),
		((5555, 5,  5,  5, 55, 55, 5555), false),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const c = cases[i].0;
		const expected = cases[i].1;
		const case_dt = new(chrono::UTC, 0,
			c.0, c.1, c.2, c.3, c.4, c.5, c.6)!;
		assert(before(case_dt, dt) == expected,
			"incorrect date ordering in before()");
	};
};

@test fn diff() void = {
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
	for (let i = 0z; i < len(cases); i += 1) {
		const dta = cases[i].0;
		const dtb = cases[i].1;
		const expected = cases[i].2;
		const actual = diff(dta, dtb);
		assert(period_eq(actual, expected), "diff miscalculation");
	};
};

@test fn unitdiff() void = {
	const cases = [
		(
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 2)!,
			new(chrono::UTC, 0, 2022, 1, 5, 13, 53, 30, 20)!,
			(27, 328, 1427, 9993, 239834, 14390073, 863404409i64,
				(863404409i64 * time::SECOND) + 18),
		),
		(
			new(chrono::UTC, 0, 1994, 8, 28, 11, 20, 1, 2)!,
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 0)!,
			(0, 0, 0, 1, 24, 1440, 86400i64,
				(86400i64 * time::SECOND) + 2),
		),
		(
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 0)!,
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 0)!,
			(0, 0, 0, 0, 0, 0, 0i64, 0i64),
		),
		(
			new(chrono::UTC, 0, -500, 1, 1, 0, 59, 1, 0)!,
			new(chrono::UTC, 0, 2000, 1, 1, 23, 1, 1, 0)!,
			(2500, 30000, 130443, 913106, 913106 * 24 + 22,
				(913106 * 24 + 22) * 60 + 2,
				((913106 * 24 + 22) * 60 + 2) * 60i64,
				(((913106 * 24 + 22) * 60 + 2) * 60i64 *
					time::SECOND)),
		),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const dta = cases[i].0;
		const dtb = cases[i].1;
		const expected = cases[i].2;
		assert(unitdiff(dtb, dta, unit::YEAR) == expected.0,
			"invalid diff_in_years() result");
		assert(unitdiff(dtb, dta, unit::MONTH) == expected.1,
			"invalid diff_in_months() result");
		assert(unitdiff(dtb, dta, unit::WEEK) == expected.2,
			"invalid diff_in_weeks() result");
		assert(unitdiff(dtb, dta, unit::DAY) == expected.3,
			"invalid diff_in_days() result");
		assert(unitdiff(dtb, dta, unit::HOUR) == expected.4,
			"invalid diff_in_hours() result");
		assert(unitdiff(dtb, dta, unit::MINUTE) == expected.5,
			"invalid diff_in_minutes() result");
		assert(unitdiff(dtb, dta, unit::SECOND) == expected.6,
			"invalid diff_in_seconds() result");
		assert(unitdiff(dtb, dta, unit::NANOSECOND) == expected.7,
			"invalid diff_in_nanoseconds() result");
	};
};

@test fn truncate() void = {
	const dt = new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 2)!;
	assert(eq(truncate(dt, unit::ERA),
			new(chrono::UTC, 0, 1, 1, 1, 0, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::YEAR),
			new(chrono::UTC, 0, 1994, 1, 1, 0, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::MONTH),
			new(chrono::UTC, 0, 1994, 8, 1, 0, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::WEEK),
			new(chrono::UTC, 0, 1994, 8, 22, 0, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::DAY),
			new(chrono::UTC, 0, 1994, 8, 27, 0, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::HOUR),
			new(chrono::UTC, 0, 1994, 8, 27, 11, 0, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::MINUTE),
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 0, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::SECOND),
			new(chrono::UTC, 0, 1994, 8, 27, 11, 20, 1, 0)!),
		"invalid truncate() result");
	assert(eq(truncate(dt, unit::NANOSECOND), dt),
		"invalid truncate() result");
};

@test fn add() void = {
	const d = new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 0)!;
	const cases = [
		(
			period { years = 1, ... },
			new(chrono::UTC, 0, 2023, 2, 4, 3, 14, 7, 0)!,
		),
		(
			period { years = -23, ... },
			new(chrono::UTC, 0, 1999, 2, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = 2, ... },
			new(chrono::UTC, 0, 2022, 4, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = 11, ... },
			new(chrono::UTC, 0, 2023, 1, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = -1, ... },
			new(chrono::UTC, 0, 2022, 1, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = -2, ... },
			new(chrono::UTC, 0, 2021, 12, 4, 3, 14, 7, 0)!,
		),
		(
			period { days = 3, ... },
			new(chrono::UTC, 0, 2022, 2, 7, 3, 14, 7, 0)!,
		),
		(
			period { days = 33, ... },
			new(chrono::UTC, 0, 2022, 3, 9, 3, 14, 7, 0)!,
		),
		(
			period { days = 333, ... },
			new(chrono::UTC, 0, 2023, 1, 3, 3, 14, 7, 0)!,
		),
		(
			period { days = -2, ... },
			new(chrono::UTC, 0, 2022, 2, 2, 3, 14, 7, 0)!,
		),
		(
			period { days = -4, ... },
			new(chrono::UTC, 0, 2022, 1, 31, 3, 14, 7, 0)!,
		),
		(
			period { days = -1337, ... },
			new(chrono::UTC, 0, 2018, 6, 8, 3, 14, 7, 0)!,
		),
		(
			period { hours = 1, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 4, 14, 7, 0)!,
		),
		(
			period { hours = 24, ... },
			new(chrono::UTC, 0, 2022, 2, 5, 3, 14, 7, 0)!,
		),
		(
			period { hours = 25, ... },
			new(chrono::UTC, 0, 2022, 2, 5, 4, 14, 7, 0)!,
		),
		(
			period { hours = 123456, ... },
			new(chrono::UTC, 0, 2036, 3, 6, 3, 14, 7, 0)!,
		),
		(
			period { hours = -2, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 1, 14, 7, 0)!,
		),
		(
			period { hours = -24, ... },
			new(chrono::UTC, 0, 2022, 2, 3, 3, 14, 7, 0)!,
		),
		(
			period { hours = -123456, ... },
			new(chrono::UTC, 0, 2008, 1, 5, 3, 14, 7, 0)!,
		),
		(
			period { seconds = 2, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 9, 0)!,
		),
		(
			period { seconds = 666666666, ... },
			new(chrono::UTC, 0, 2043, 3, 22, 4, 25, 13, 0)!,
		),
		(
			period { seconds = -2, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 5, 0)!,
		),
		(
			period { seconds = -666666666, ... },
			new(chrono::UTC, 0, 2000, 12, 20, 2, 3, 1, 0)!,
		),
		(
			period { nanoseconds = 123, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 123)!,
		),
		(
			period { nanoseconds = 1361661361461, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 3, 36, 48, 661361461)!,
		),
		(
			period { nanoseconds = -1361661361461, ... },
			new(chrono::UTC, 0, 2022, 2, 4, 2, 51, 25, 338638539)!,
		),
		(
			period { months = 1, seconds = -666666666, ... },
			new(chrono::UTC, 0, 2001, 1, 17, 2, 3, 1, 0)!,
		),
		(
			period { months = 1, seconds = -666666666, ... },
			new(chrono::UTC, 0, 2001, 1, 17, 2, 3, 1, 0)!,
		),
		(
			period {
				years = -1,
				months = -2,
				weeks = -3,
				days = -4,
				hours = -5,
				minutes = -6,
				seconds = -7,
				nanoseconds = -8,
				...
			},
			new(chrono::UTC, 0, 2020, 11, 8, 22, 7, 59, 999999992)!,
		),
		(
			period {
				years = 1,
				months = 2,
				weeks = 3,
				days = 4,
				hours = 5,
				minutes = 6,
				seconds = 7,
				nanoseconds = 8,
				...
			},
			new(chrono::UTC, 0, 2023, 4, 29, 8, 20, 14, 8)!,
		),
		(
			period {
				years = 1,
				months = -2,
				weeks = 3,
				days = -5,
				hours = 8,
				minutes = -13,
				seconds = 21,
				nanoseconds = -34,
				...
			},
			new(chrono::UTC, 0, 2022, 12, 20, 11, 1, 27, 999999966)!,
		),
		(
			period {
				years = -1,
				months = 12,
				weeks = -52,
				days = -31,
				hours = 24,
				minutes = -3600,
				seconds = 3600,
				nanoseconds = -86400000000000,
				...
			},
			new(chrono::UTC, 0, 2021, 1, 2, 16, 14, 7, 0)!,
		),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const p = cases[i].0;
		const expected = cases[i].1;
		const actual = add(d, calculus::DEFAULT, p);
		assert(eq(actual, expected), "addition miscalculation");
	};
};

@test fn sub() void = {
	const d = new(chrono::UTC, 0, 2022, 2, 4, 3, 14, 7, 0)!;
	const cases = [
		(
			period { years = 1, ... },
			new(chrono::UTC, 0, 2021, 2, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = 2, ... },
			new(chrono::UTC, 0, 2021, 12, 4, 3, 14, 7, 0)!,
		),
		(
			period { months = 14, ... },
			new(chrono::UTC, 0, 2020, 12, 4, 3, 14, 7, 0)!,
		),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const p = cases[i].0;
		const expected = cases[i].1;
		const actual = sub(d, calculus::DEFAULT, p);
		assert(eq(actual, expected), "subtraction miscalculation");
	};
};
