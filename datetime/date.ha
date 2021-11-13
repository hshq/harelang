use time::chrono;
use errors;

// Represents an ISO calendar date.
// Instances created from datetime:: functions are guaranteed to be valid.
export type localdate = struct {
	era:      (void | int),
	year:     (void | int),
	month:    (void | int),
	day:      (void | int),
	weekyear: (void | int),
	week:     (void | int),
	weekday:  (void | int),
	yearday:  (void | int),
};

export fn init_date() localdate = localdate {
	era      = void,
	year     = void,
	month    = void,
	day      = void,
	weekyear = void,
	week     = void,
	weekday  = void,
	yearday  = void,
};

// TODO: The following function can be split up for efficiency.
// calc_y, calc_m, calc_d, etc.

// Populates the year, month, and day fields of a given [[localdate]],
// calculated from a [[chrono::epochal]]
export fn calc_ymd(epochal: chrono::epochal, ld: *localdate) void = {
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day#Julian_or_Gregorian_calendar_from_Julian_day_number
	//
	// Alternate methods of date calculation should be explored.
	const J = epochal - EPOCH_JULIAN;
	const j = 1401;
	const y = 4716;
	const B = 274277;
	const C = -38;
	const r = 4;
	const v = 3;
	const p = 1461;
	const u = 5;
	const w = 2;
	const s = 153;
	const n = 12;
	const m = 2;

	const f = J + j + (((4 * J + B) / 146097) * 3) / 4 + C;
	const e = r * f + v;
	const g = (e % p) / r;
	const h = u * g + w;

	const D = (h % s) / u + 1;
	const M = ((h / s + m) % n) + 1;
	const Y = (e / p) - y + (n + m - M) / n;

	ld.year = Y: int;
	ld.month = M: int;
	ld.day = D: int;
};

export fn calc_ywd(e: chrono::epochal, ld: *localdate) void = {
	// TODO
	ld.year = 0;
	ld.week = 0;
	ld.weekday = 0;
	return;
};

export fn calc_yd(e: chrono::epochal, ld: *localdate) void = {
	// TODO
	ld.year = 0;
	ld.yearday = 0;
	return;
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
	if (
		// TODO: split up calc_ymd for finer grained
		// calculating and populating
		want.year is int
		|| want.month is int
		|| want.day is int
	) {
		calc_ymd(e, date);
	};
	if (
		want.year is int
		|| want.week is int
		|| want.weekday is int
	) {
		calc_ywd(e, date);
	};
	if (
		want.year is int
		|| want.yearday is int
	) {
		calc_yd(e, date);
	};
};

// Converts a year-month-day date into an [[chrono::epocal]]
export fn epocal_from_ymd(y: int, m: int, d: int) (chrono::epochal | errors::invalid) = {
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
export fn epocal_from_ywd() (chrono::epochal | errors::invalid) = {
	// TODO
	return 0;
};

// Converts a year-yearday date into an [[chrono::epocal]]
export fn epocal_from_yd() (chrono::epochal | errors::invalid) = {
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
