use fmt;
use time::chrono;
use time;

// Represents a span of time in the proleptic Gregorian calendar,
// using relative units of time. Used for calendar arithmetic.
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

// Prints to stdout the representation of a period.
//
// TODO: This is a debug utility. Remove this in favour of changing format() to
// accept arguments of type (datetime | period), using the "intervals" standard
// representation provided by ISO 8601.
//
// See https://en.wikipedia.org/wiki/ISO_8601#Time_intervals
export fn print_period(p: period) void = {
	fmt::printfln(
		"eras: {}\nyears: {}\nmonths: {}\nweeks: {}\ndays: {}\n"
		"hours: {}\nminutes: {}\nseconds: {}\nnanoseconds: {}",
		p.eras, p.years, p.months, p.weeks, p.days, p.hours,
		p.minutes, p.seconds, p.nanoseconds
	)!;
};

// Specifies behaviour during calendar arithmetic
//
// * DEFAULT
// Units are added in the order of largest (years) to smallest (nanoseconds). If
// the resulting date does not exist, the first extant date previous to the
// initial result is returned.
export type calculus = enum int {
	DEFAULT,
};

// The various datetime units that can be used for arithmetic
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

// Returns whether or not two dates are numerically equal
export fn eq(a: datetime, b: datetime) bool = {
	return a.date == b.date && a.time == b.time;
};

// Returns whether or not the first date is after the second date
export fn is_after(a: datetime, b: datetime) bool = {
	return !eq(a, b) &&
		(a.date > b.date || a.date == b.date && a.time > b.time);
};

// Returns whether or not the first date is before the second date
export fn is_before(a: datetime, b: datetime) bool = {
	return !eq(a, b) && !is_after(a, b);
};

// Calculates the difference between two datetimes
export fn diff(a: datetime, b: datetime) period = {
	let res = period { ... };
	if (eq(a, b)) {
		return res;
	};
	if (is_after(b, a)) {
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

	res.minutes = min(&a) - min(&b);
	if (res.minutes < 0) {
		res.hours -= 1;
		res.minutes = 60 + res.minutes;
	};

	res.seconds = sec(&a) - sec(&b);
	if (res.seconds < 0) {
		res.minutes -= 1;
		res.seconds = 60 + res.seconds;
	};

	res.nanoseconds = nsec(&a) - nsec(&b);
	if (res.nanoseconds < 0) {
		res.seconds -= 1;
		res.nanoseconds = time::SECOND + res.nanoseconds;
	};

	return res;
};

// Calculates the difference between two datetimes in the given unit. An integer
// is returned, with the fractional part of the difference being discarded.
export fn diff_in_unit(a: datetime, b: datetime, u: unit) i64 = {
	return switch (u) {
	case unit::ERA =>
		yield absi(era(&a) - era(&b));
	case unit::YEAR =>
		yield diff(a, b).years;
	case unit::MONTH =>
		const full_diff = diff(a, b);
		yield full_diff.years * 12 + full_diff.months;
	case unit::WEEK =>
		yield diff_in_unit(a, b, unit::DAY) / 7;
	case unit::DAY =>
		yield absi(a.date - b.date): int;
	case unit::HOUR =>
		const full_diff = diff(a, b);
		yield (diff_in_unit(a, b, unit::DAY) * 24) + full_diff.hours;
	case unit::MINUTE =>
		const full_diff = diff(a, b);
		yield diff_in_unit(a, b, unit::HOUR) * 60 + full_diff.minutes;
	case unit::SECOND =>
		const full_diff = diff(a, b);
		yield diff_in_unit(a, b, unit::MINUTE) * 60 + full_diff.seconds;
	case unit::NANOSECOND =>
		const full_diff = diff(a, b);
		yield diff_in_unit(a, b, unit::SECOND) * time::SECOND +
			full_diff.nanoseconds;
	};
};

// Returns whether or not two periods are numerically equal
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

// Returns the given datetime at the start of a particular given unit, e.g.
// the start of the day or the start of the minute.
export fn start_of(u: unit, dt: datetime) datetime = {
	// TODO: Replace all of the 0s for the zoffset with the actual
	// zoffset once the API is solidified a bit
	return switch (u) {
	case unit::ERA =>
		yield new(dt.loc, 0,
			01, 01, 01,
			00, 00, 00, 0,
		)!;
	case unit::YEAR =>
		yield new(dt.loc, 0,
			year(&dt), 01, 01,
			00, 00, 00, 0,
		)!;
	case unit::MONTH =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), 01,
			00, 00, 00, 0,
		)!;
	case unit::WEEK =>
		const epochal = dt.date - (weekday(&dt) - 1);
		const ymd = calc_ymd(epochal);
		yield new(dt.loc, 0,
			ymd.0, ymd.1, ymd.2,
			00, 00, 00, 0,
		)!;
	case unit::DAY =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			00, 00, 00, 0,
		)!;
	case unit::HOUR =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), 00, 00, 0,
		)!;
	case unit::MINUTE =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), min(&dt), 00, 0,
		)!;
	case unit::SECOND =>
		yield new(dt.loc, 0,
			year(&dt), month(&dt), day(&dt),
			hour(&dt), min(&dt), sec(&dt), 0,
		)!;
	case unit::NANOSECOND =>
		yield dt;
	};
};

// Hops, starting from a datetime, to static inter-period points along the
// calendar, according to the given periods, and returns a new datetime.
// Inter-period points are the starts of years, months, days, etc.
//
// hop() consults each period's fields in order of largest to smallest
// calendrically (from years to nanoseconds).
//
// If a field's value N is zero, nothing happens. Otherwise, hop() will reckon
// to the Nth inter-period point from where last reckoned. This repeats until
// all the given period's fields are exhausted.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::hop(dt, datetime::period {
// 		years  = 22, // produces 2021-01-01 00:00:00
// 		months = -1, // produces 2020-11-01 00:00:00
// 		days   = -4, // produces 2020-10-27 00:00:00
// 	});
//
export fn hop(dt: datetime, pp: period...) datetime = {
	let new_dt = clone(dt);
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];

		if (p.years != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { years = p.years, ... });
			new_dt = start_of(unit::YEAR, dt_inc);
		};
		if (p.months != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { months = p.months, ... });
			new_dt = start_of(unit::MONTH, dt_inc);
		};
		if (p.weeks != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { weeks = p.weeks, ... });
			new_dt = start_of(unit::WEEK, dt_inc);
		};
		if (p.days != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { days = p.days, ... });
			new_dt = start_of(unit::DAY, dt_inc);
		};
		if (p.hours != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { hours = p.hours, ... });
			new_dt = start_of(unit::HOUR, dt_inc);
		};
		if (p.minutes != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { minutes = p.minutes, ... });
			new_dt = start_of(unit::MINUTE, dt_inc);
		};
		if (p.seconds != 0) {
			const dt_inc = add(new_dt, calculus::DEFAULT,
				period { seconds = p.seconds, ... });
			new_dt = start_of(unit::SECOND, dt_inc);
		};
		if (p.nanoseconds != 0) {
			new_dt = add(new_dt, calculus::DEFAULT,
				period { nanoseconds = p.nanoseconds, ... });
		};
	};
	return new_dt;
};

// Adds a calendrical period of time to a datetime, largest units first.
// Tries to conserve relative distance from cyclical points on the calendar.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::add(dt, datetime::calculus::DEFAULT, datetime::period {
// 		years  = 22, // 2021-05-13 12:30:45
// 		months = -1, // 2021-04-13 12:30:45
// 		days   = -4, // 2020-04-09 12:30:45
// 	});
export fn add(dt: datetime, flag: calculus, pp: period...) datetime = {
	// TODO: Use builder to simplify some code.
	let d_year = year(&dt);
	let d_month = month(&dt);
	let d_day = day(&dt);
	let d_hour = hour(&dt);
	let d_min = min(&dt);
	let d_sec = sec(&dt);
	let d_nsec = ((nsec(&dt)): i64);
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];

		let latest_epochal = dt.date;

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
		latest_epochal = calc_epochal_from_ymd(
			d_year, d_month, d_day)!;
		if (p.days != 0) {
			const new_ymd = calc_ymd(latest_epochal + p.days);
			d_year = new_ymd.0;
			d_month = new_ymd.1;
			d_day = new_ymd.2;
			latest_epochal = calc_epochal_from_ymd(
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

			if (absi(p.nanoseconds) > ns_in_day) {
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
				const new_epochal = latest_epochal +
					overflowed_days;
				const new_ymd = calc_ymd(new_epochal);
				d_year = new_ymd.0;
				d_month = new_ymd.1;
				d_day = new_ymd.2;
			};
			const new_hmsn = calc_hmsn(new_time);
			d_hour = new_hmsn.0;
			d_min = new_hmsn.1;
			d_sec = new_hmsn.2;
			d_nsec = new_hmsn.3;
		};
	};
	// TODO: Add zoffset back in here once API is settled
	return new(dt.loc, 0,
		d_year, d_month, d_day, d_hour, d_min, d_sec, d_nsec: int,
	)!;
};

// Subtracts a calendrical period of time to a datetime, largest units first.
// Tries to conserve relative distance from cyclical points on the calendar.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::subtract(dt, datetime::calculus::DEFAULT, datetime::period {
// 		years  = 22, // 1977-05-13 12:30:45
// 		months = -1, // 1977-06-13 12:30:45
// 		days   = -4, // 1977-06-17 12:30:45
// 	});
export fn subtract(dt: datetime, flag: calculus, pp: period...) datetime = {
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

// Copied from math:: to avoid dependancy.
fn absi(n: i64) i64 = {
	if (n < 0) {
		return -n;
	} else {
		return n;
	};
};

@test fn eq() void = {
	const dt = new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 0)!;
	const cases = [
		((-768, 01, 01, 03, 14, 07, 0), false),
		((1, 1, 01, 14, 00, 00, 1234), false),
		((2022, 02, 04, 03, 14, 07, 0), true),
		((2022, 02, 04, 03, 14, 07, 1), false),
		((2038, 01, 19, 03, 14, 07, 0), false),
		((5555, 05, 05, 05, 55, 55, 5555), false),
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

@test fn is_after() void = {
	const dt = new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 0)!;
	const cases = [
		((-768, 01, 01, 03, 14, 07, 0), false),
		((1, 1, 01, 14, 00, 00, 1234), false),
		((2020, 02, 04, 03, 14, 07, 1), false),
		((2022, 02, 04, 03, 14, 07, 0), false),
		((2022, 02, 04, 04, 01, 01, 0), true),
		((2038, 01, 19, 03, 14, 07, 0), true),
		((5555, 05, 05, 05, 55, 55, 5555), true),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const c = cases[i].0;
		const expected = cases[i].1;
		const case_dt = new(chrono::UTC, 0,
			 c.0, c.1, c.2, c.3, c.4, c.5, c.6)!;
		assert(is_after(case_dt, dt) == expected,
			"incorrect date ordering in is_after()");
	};
};

@test fn is_before() void = {
	const dt = new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 0)!;
	const cases = [
		((-768, 01, 01, 03, 14, 07, 0), true),
		((1, 1, 01, 14, 00, 00, 1234), true),
		((2020, 02, 04, 03, 14, 07, 1), true),
		((2022, 02, 04, 03, 14, 07, 0), false),
		((2022, 02, 04, 04, 01, 01, 0), false),
		((2038, 01, 19, 03, 14, 07, 0), false),
		((5555, 05, 05, 05, 55, 55, 5555), false),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const c = cases[i].0;
		const expected = cases[i].1;
		const case_dt = new(chrono::UTC, 0,
			 c.0, c.1, c.2, c.3, c.4, c.5, c.6)!;
		assert(is_before(case_dt, dt) == expected,
			"incorrect date ordering in is_before()");
	};
};

@test fn diff() void = {
	const cases = [
		(
			new(chrono::UTC, 0, 2021, 01, 15, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2022, 02, 16, 00, 00, 00, 0)!,
			period {
				years = 1,
				months = 1,
				days = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 01, 15, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2022, 03, 27, 00, 00, 00, 0)!,
			period {
				years = 1,
				months = 2,
				days = 12,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 01, 15, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2022, 03, 14, 00, 00, 00, 0)!,
			period {
				years = 1,
				months = 1,
				days = 27,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 01, 15, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2021, 01, 16, 00, 00, 00, 0)!,
			period {
				days = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2021, 01, 15, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2021, 01, 16, 01, 03, 02, 4)!,
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
			new(chrono::UTC, 0, 2021, 01, 15, 02, 03, 02, 2)!,
			new(chrono::UTC, 0, 2021, 01, 16, 01, 01, 02, 4)!,
			period {
				hours = 22,
				minutes = 58,
				nanoseconds = 2,
				...
			},
		),
		(
			new(chrono::UTC, 0, 0500, 01, 01, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 3500, 01, 01, 00, 06, 00, 0)!,
			period {
				years = 3000,
				minutes = 6,
				...
			},
		),
		(
			new(chrono::UTC, 0, -500, 01, 01, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2500, 01, 01, 00, 06, 00, 0)!,
			period {
				years = 3000,
				minutes = 6,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2000, 01, 01, 00, 00, 00, 0)!,
			new(chrono::UTC, 0, 2000, 01, 01, 00, 06, 00, 999999999)!,
			period {
				minutes = 6,
				nanoseconds = 999999999,
				...
			},
		),
		(
			new(chrono::UTC, 0, 2000, 01, 01, 00, 06, 00, 999999999)!,
			new(chrono::UTC, 0, 2000, 01, 01, 00, 06, 01, 0)!,
			period {
				nanoseconds = 1,
				...
			},
		),
		(
			new(chrono::UTC, 0, -4000, 01, 01, 00, 06, 00, 999999999)!,
			new(chrono::UTC, 0, 4000, 01, 01, 00, 06, 01, 0)!,
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

@test fn diff_in_unit() void = {
	const cases = [
		(
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 2)!,
			new(chrono::UTC, 0, 2022, 01, 05, 13, 53, 30, 20)!,
			(27, 328, 1427, 9993, 239834, 14390073, 863404409i64,
				(863404409i64 * time::SECOND) + 18),
		),
		(
			new(chrono::UTC, 0, 1994, 08, 28, 11, 20, 01, 2)!,
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 0)!,
			(0, 0, 0, 1, 24, 1440, 86400i64,
				(86400i64 * time::SECOND) + 2),
		),
		(
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 0)!,
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 0)!,
			(0, 0, 0, 0, 0, 0, 0i64, 0i64),
		),
		(
			new(chrono::UTC, 0, -500, 01, 01, 00, 59, 01, 0)!,
			new(chrono::UTC, 0, 2000, 01, 01, 23, 01, 01, 0)!,
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
		assert(diff_in_unit(dtb, dta, unit::YEAR) == expected.0,
			"invalid diff_in_years() result");
		assert(diff_in_unit(dtb, dta, unit::MONTH) == expected.1,
			"invalid diff_in_months() result");
		assert(diff_in_unit(dtb, dta, unit::WEEK) == expected.2,
			"invalid diff_in_weeks() result");
		assert(diff_in_unit(dtb, dta, unit::DAY) == expected.3,
			"invalid diff_in_days() result");
		assert(diff_in_unit(dtb, dta, unit::HOUR) == expected.4,
			"invalid diff_in_hours() result");
		assert(diff_in_unit(dtb, dta, unit::MINUTE) == expected.5,
			"invalid diff_in_minutes() result");
		assert(diff_in_unit(dtb, dta, unit::SECOND) == expected.6,
			"invalid diff_in_seconds() result");
		assert(diff_in_unit(dtb, dta, unit::NANOSECOND) == expected.7,
			"invalid diff_in_nanoseconds() result");
	};
};

@test fn start_of() void = {
	const dt = new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 2)!;
	assert(eq(start_of(unit::ERA, dt),
			new(chrono::UTC, 0, 01, 01, 01, 00, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::YEAR, dt),
			new(chrono::UTC, 0, 1994, 01, 01, 00, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::MONTH, dt),
			new(chrono::UTC, 0, 1994, 08, 01, 00, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::WEEK, dt),
			new(chrono::UTC, 0, 1994, 08, 22, 00, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::DAY, dt),
			new(chrono::UTC, 0, 1994, 08, 27, 00, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::HOUR, dt),
			new(chrono::UTC, 0, 1994, 08, 27, 11, 00, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::MINUTE, dt),
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 00, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::SECOND, dt),
			new(chrono::UTC, 0, 1994, 08, 27, 11, 20, 01, 0)!),
		"invalid start_of() result");
	assert(eq(start_of(unit::NANOSECOND, dt), dt),
		"invalid start_of() result");
};

@test fn add() void = {
	const d = new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 0)!;
	const cases = [
		(
			period { years = 1, ... },
			new(chrono::UTC, 0, 2023, 02, 04, 03, 14, 07, 0)!,
		),
		(
			period { years = -23, ... },
			new(chrono::UTC, 0, 1999, 02, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = 2, ... },
			new(chrono::UTC, 0, 2022, 04, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = 11, ... },
			new(chrono::UTC, 0, 2023, 01, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = -1, ... },
			new(chrono::UTC, 0, 2022, 01, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = -2, ... },
			new(chrono::UTC, 0, 2021, 12, 04, 03, 14, 07, 0)!,
		),
		(
			period { days = 3, ... },
			new(chrono::UTC, 0, 2022, 02, 07, 03, 14, 07, 0)!,
		),
		(
			period { days = 33, ... },
			new(chrono::UTC, 0, 2022, 03, 09, 03, 14, 07, 0)!,
		),
		(
			period { days = 333, ... },
			new(chrono::UTC, 0, 2023, 01, 03, 03, 14, 07, 0)!,
		),
		(
			period { days = -2, ... },
			new(chrono::UTC, 0, 2022, 02, 02, 03, 14, 07, 0)!,
		),
		(
			period { days = -4, ... },
			new(chrono::UTC, 0, 2022, 01, 31, 03, 14, 07, 0)!,
		),
		(
			period { days = -1337, ... },
			new(chrono::UTC, 0, 2018, 06, 08, 03, 14, 07, 0)!,
		),
		(
			period { hours = 1, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 04, 14, 07, 0)!,
		),
		(
			period { hours = 24, ... },
			new(chrono::UTC, 0, 2022, 02, 05, 03, 14, 07, 0)!,
		),
		(
			period { hours = 25, ... },
			new(chrono::UTC, 0, 2022, 02, 05, 04, 14, 07, 0)!,
		),
		(
			period { hours = 123456, ... },
			new(chrono::UTC, 0, 2036, 03, 06, 03, 14, 07, 0)!,
		),
		(
			period { hours = -2, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 01, 14, 07, 0)!,
		),
		(
			period { hours = -24, ... },
			new(chrono::UTC, 0, 2022, 02, 03, 03, 14, 07, 0)!,
		),
		(
			period { hours = -123456, ... },
			new(chrono::UTC, 0, 2008, 01, 05, 03, 14, 07, 0)!,
		),
		(
			period { seconds = 2, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 09, 0)!,
		),
		(
			period { seconds = 666666666, ... },
			new(chrono::UTC, 0, 2043, 03, 22, 04, 25, 13, 0)!,
		),
		(
			period { seconds = -2, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 05, 0)!,
		),
		(
			period { seconds = -666666666, ... },
			new(chrono::UTC, 0, 2000, 12, 20, 02, 03, 01, 0)!,
		),
		(
			period { nanoseconds = 123, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 123)!,
		),
		(
			period { nanoseconds = 1361661361461, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 03, 36, 48, 661361461)!,
		),
		(
			period { nanoseconds = -1361661361461, ... },
			new(chrono::UTC, 0, 2022, 02, 04, 02, 51, 25, 338638539)!,
		),
		(
			period { months = 1, seconds = -666666666, ... },
			new(chrono::UTC, 0, 2001, 01, 17, 02, 03, 01, 0)!,
		),
		(
			period { months = 1, seconds = -666666666, ... },
			new(chrono::UTC, 0, 2001, 01, 17, 02, 03, 01, 0)!,
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
			new(chrono::UTC, 0, 2020, 11, 08, 22, 07, 59, 999999992)!,
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
			new(chrono::UTC, 0, 2023, 04, 29, 08, 20, 14, 8)!,
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
			new(chrono::UTC, 0, 2022, 12, 20, 11, 01, 27, 999999966)!,
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
			new(chrono::UTC, 0, 2021, 01, 02, 16, 14, 07, 0)!,
		),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const p = cases[i].0;
		const expected = cases[i].1;
		const actual = add(d, calculus::DEFAULT, p);
		if (!eq(actual, expected)) {
			fmt::printfln("attempting to add:")!;
			print_period(p);
			fmt::printfln("expected {}",
				format("%F %T.%N", &expected)!)!;
			fmt::printfln("was {}\n",
				format("%F %T.%N", &actual)!)!;
		};
		assert(eq(actual, expected), "addition miscalculation");
	};
};

@test fn subtract() void = {
	const d = new(chrono::UTC, 0, 2022, 02, 04, 03, 14, 07, 0)!;
	const cases = [
		(
			period { years = 1, ... },
			new(chrono::UTC, 0, 2021, 02, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = 2, ... },
			new(chrono::UTC, 0, 2021, 12, 04, 03, 14, 07, 0)!,
		),
		(
			period { months = 14, ... },
			new(chrono::UTC, 0, 2020, 12, 04, 03, 14, 07, 0)!,
		),
	];
	for (let i = 0z; i < len(cases); i += 1) {
		const p = cases[i].0;
		const expected = cases[i].1;
		const actual = subtract(d, calculus::DEFAULT, p);
		assert(eq(actual, expected), "subtraction miscalculation");
	};
};
