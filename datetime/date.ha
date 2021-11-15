use time::chrono;
use errors;

// Represents an ISO calendar date.
// Instances created from datetime:: functions are guaranteed to be valid.
export type localdate = struct {
	era:         (void | int),
	year:        (void | int),
	month:       (void | int),
	day:         (void | int),
	yearday:     (void | int),
	isoweekyear: (void | int),
	isoweek:     (void | int),
	week:        (void | int),
	weekday:     (void | int),
};

export fn init_date() localdate = localdate {
	era         = void,
	year        = void,
	month       = void,
	day         = void,
	yearday     = void,
	isoweekyear = void,
	isoweek     = void,
	week        = void,
	weekday     = void,
};

export type WEEKDAYS = enum int {
	MON = 1,
	TUE = 2,
	WED = 3,
	THU = 4,
	FRI = 5,
	SAT = 6,
	SUN = 7,
};


// Calculates an era, given a year
fn calc_era(y: int) int = {
	return if (y >= 0) {
		yield 1; // CE "Common Era"
	} else {
		yield 0; // BCE "Before Common Era"
	};
};


// Calculates the (year, month, day) of a [[chrono::epochal]]
//
// TODO: Split up this function? Probably not. Most useful as is.
fn calc_ymd(e: chrono::epochal) (int, int, int) = {
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day#Julian_or_Gregorian_calendar_from_Julian_day_number
	//
	// Alternate methods of date calculation should be explored.
	const J = e - EPOCH_JULIAN;

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

// Calculates the day of a year, given a year, month, and day
fn calc_yearday(y: int, m: int, d: int) int = {
	const months_firsts: [_]int = [
		0, 31, 59,
		90, 120, 151,
		181, 212, 243,
		273, 304, 334,
	];

	if (m >= 2 && is_leap_year(y)) {
		return months_firsts[m - 1] + d + 1;
	} else {
		return months_firsts[m - 1] + d;
	};
};

// Calculates the ISO week-numbering year,
// given a year, month, day, and weekday
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

// Calculates the ISO week of a [[chrono::epochal]]
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
// given a yearday and weekday.
// All days in a new year before the year's first Monday belong to week 0.
fn calc_week(yd: int, wd: int) int = {
	return (5 + yd - wd) / 7;
};

// Calculates the weekday of a [[chrono::epochal]],
// from Monday=1 to Sunday=7
fn calc_weekday(e: chrono::epochal) int = {
	const wd = ((e + 3) % 7 + 1): int;
	return if (wd > 0) wd else wd + 7;
};

// Calculates the weekday of a [[chrono::epochal]],
// from Monday=0 to Sunday=6
fn calc_zeroweekday(wd: int) int = {
	return wd - 1;
};

// Calculates whether a given year is a leap year.
fn is_leap_year(y: int) bool = {
	return if (y % 4 != 0) false
	else if (y % 100 != 0) true
	else if (y % 400 != 0) false
	else true;
};

// Converts a [[chrono::epocal]] to a [[localdate]]. The fields in "date" are
// populated acording to which fields in "want" are non-void.
//
//	let date = localdate { ... };
//	let want = localdate { year=0, month=0, day=0, ... };
// 	conv_epochal_localdate(10724, &date, &want);
// 	assert(date == localdate { year=1999, month=5, day=13, ... });
//
export fn conv_epochal_localdate(
	e: chrono::epochal,
	date: *localdate,
	want: *localdate,
) void = {
	if (want.year is int || want.month is int || want.day is int) {
		const ymd = calc_ymd(e);
		date.year = ymd.0;
		date.month = ymd.1;
		date.day = ymd.2;
	};

	if (want.yearday is int) {
		if (date.year is void || date.month is void || date.day is void) {
			const ymd = calc_ymd(e);
			date.year = ymd.0;
			date.month = ymd.1;
			date.day = ymd.2;
		};
		calc_yearday(date.year: int, date.month: int, date.day: int);
	};

	if (want.week is int) {
		// TODO
		//calc_isoweek(e);
		void;
	};

	if (want.weekday is int) {
		date.weekday = calc_weekday(e);
	};
};

// Converts a year-month-day date into an [[chrono::epocal]]
fn epocal_from_ymd(y: int, m: int, d: int) (chrono::epochal | errors::invalid) = {
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
	const epochal = jdn + EPOCH_JULIAN;
	return epochal;

};

// Converts a year-week-weekday date into an [[chrono::epocal]]
fn epocal_from_ywd() (chrono::epochal | errors::invalid) = {
	// TODO
	return 0;
};

// Converts a year-yearday date into an [[chrono::epocal]]
fn epocal_from_yd() (chrono::epochal | errors::invalid) = {
	// TODO
	return 0;
};

// Converts a [[localdate]] to a [[chrono::epocal]].
// Fails if there is insufficient information in the given [[localdate]].
export fn conv_localdate_epochal(ld: localdate) (chrono::epochal | errors::invalid) = {
	if (
		ld.year is int
		&& ld.month is int
		&& ld.day is int
	) {
		return epocal_from_ymd(
			ld.year: int,
			ld.month: int,
			ld.day: int,
		);
	} else if (
		ld.year is int
		&& ld.week is int
		&& ld.weekday is int
	) {
		return 0; // TODO
	} else if (
		ld.year is int
		&& ld.yearday is int
	) {
		return 0; // TODO
	};

	return errors::invalid;
};
