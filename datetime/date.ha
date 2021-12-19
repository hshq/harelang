use errors;
use time::chrono;

// Calculates whether a given year is a leap year.
export fn is_leap_year(y: int) bool = {
	return if (y % 4 != 0) false
	else if (y % 100 != 0) true
	else if (y % 400 != 0) false
	else true;
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

// Calculates the day of a year, given a (year, month, day) date
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
	return (5 + yd - wd) / 7;
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
fn calc_epochal_from_ymd(y: int, m: int, d: int) (chrono::epochal | errors::invalid) = {
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
	const e = jdn + EPOCH_JULIAN;
	return e;
};

// Calculates the [[chrono::epochal]], given a (year, week, weekday) date
fn calc_epochal_from_ywd(y: int, w: int, wd: int) (chrono::epochal | errors::invalid) = {
	// TODO
	return 0;
};

// Calculates the [[chrono::epochal]], given a (year, yearday) date
fn calc_epochal_from_yd(y: int, yd: int) (chrono::epochal | errors::invalid) = {
	// TODO
	return 0;
};
