use errors;
use time::chrono;
use time;


// The epoch of the Julian Day Number
export def EPOCH_JULIAN: i64 = -2440588;

// The epoch of the Common Era
export def EPOCH_COMMONERA: i64 = -719164;


// Converts a [[datetime]] to a [[chrono::moment]].
// Fails if there is insufficient information in the [[datetime]].
export fn conv_datetime_moment(dt: datetime) (chrono::moment | errors::invalid) = {
	const d = conv_localdate_epochal(dt.date)?;
	const t = conv_localtime_time(dt.time)?;
	const m = chrono::moment {
		date = d,
		time = t,
		loc = chrono::local, // TODO
	};
	return m;
};

// Converts a [[chrono::moment]] to a [[datetime]]
export fn conv_moment_datetime(m: chrono::moment, dt: *datetime) void = {
	conv_epochal_localdate(m.date, &(dt.date), &localdate {
		// TODO: reconcile, add more fields when ready
		year = 0,
		month = 0,
		day = 0,
		...
	});

	const lt = conv_time_localtime(m.time);
	dt.time = lt;

	dt.loc = chrono::local; // TODO
	return dt;
};


//
// date-like
//

// Evaluates a datetime's number of days since the calendar epoch 0001-01-01
export fn epochal(dt: *datetime) int = {
	match (dt.date.epochal) {
	case void =>
		abort("TODO"); // How to resolve? Use calc_epochal_from_*?
	case e: int =>
		return e;
	};
};

// Evaluates a datetime's era
export fn era(dt: *datetime) int = {
	match (dt.date.era) {
	case void =>
		if (dt.date.year is void) {
			dt.date.year = year(dt);
		};
		dt.date.era = calc_era(dt.date.year: int);
		return dt.date.era: int;
	case a: int =>
		return a;
	};
};

// Evaluates a datetime's year
export fn year(dt: *datetime) int = {
	match (dt.date.year) {
	case void =>
		match (dt.date.epochal) {
		case void =>
			abort("TODO");
		case e: int =>
			const ymd = calc_ymd(e);
			dt.date.year = ymd.0;
			return dt.date.year: int;
		};
	case y: int =>
		return y;
	};
};

// Evaluates a datetime's month
export fn month(dt: *datetime) int = {
	match (dt.date.month) {
	case void =>
		match (dt.date.epochal) {
		case void =>
			abort("TODO");
		case e: int =>
			const ymd = calc_ymd(e);
			dt.date.month = ymd.1;
			return dt.date.month: int;
		};
	case y: int =>
		return y;
	};
};

// Evaluates a datetime's day of the month
export fn day(dt: *datetime) int = {
	match (dt.date.day) {
	case void =>
		match (dt.date.epochal) {
		case void =>
			abort("TODO");
		case e: int =>
			const ymd = calc_ymd(e);
			dt.date.day = ymd.2;
			return dt.date.day: int;
		};
	case y: int =>
		return y;
	};
};


// Evaluates a datetime's day of the week
export fn weekday(dt: *datetime) int = {
	match (dt.date.weekday) {
	case void =>
		match (dt.date.epochal) {
		case void =>
			abort("TODO");
		case e: int =>
			dt.date.weekday = calc_weekday(e);
			return dt.date.weekday: int;
		};
	case y: int =>
		return y;
	};
};

// Evaluates a datetime's ordinal day of the year
export fn yearday(dt: *datetime) int = {
	match (dt.date.yearday) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.month is void) {
			month(dt);
		};
		if (dt.date.day is void) {
			day(dt);
		};
		dt.date.yearday = calc_yearday(
			dt.date.year: int,
			dt.date.month: int,
			dt.date.day: int,
		);
		return dt.date.yearday: int;
	case yd: int =>
		return yd;
	};
};
// Evaluates a datetime's ISO week calendar year
export fn isoweekyear(dt: *datetime) int = {
	match (dt.date.isoweekyear) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.month is void) {
			month(dt);
		};
		if (dt.date.day is void) {
			day(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		dt.date.isoweekyear = calc_isoweekyear(
			dt.date.year: int,
			dt.date.month: int,
			dt.date.day: int,
			dt.date.weekday: int,
		);
		return dt.date.isoweekyear: int;
	case iwy: int =>
		return iwy;
	};
};

// Evaluates a datetime's Gregorian week
export fn week(dt: *datetime) int = {
	match (dt.date.week) {
	case void =>
		if (dt.date.yearday is void) {
			yearday(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		dt.date.week = calc_week(
			dt.date.yearday: int,
			dt.date.weekday: int,
		);
		return dt.date.week: int;
	case w: int =>
		return w;
	};
};

// Evaluates a datetime's ISO week
export fn isoweek(dt: *datetime) int = {
	match (dt.date.isoweek) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.week is void) {
			week(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		if (dt.date.yearday is void) {
			yearday(dt);
		};
		dt.date.isoweek = calc_isoweek(
			dt.date.year: int,
			dt.date.week: int,
			dt.date.weekday: int,
			dt.date.yearday: int,
		);
		return dt.date.isoweek: int;
	case iw: int =>
		return iw;
	};
};

//
// time-like
//

// Evaluates a datetime's hour of the day
export fn hour(dt: *datetime) int = {
	match (dt.time.hour) {
	case void =>
		abort("TODO");
	case h: int =>
		return h;
	};
};

// Evaluates a datetime's minute of the hour
export fn min(dt: *datetime) int = {
	match (dt.time.min) {
	case void =>
		abort("TODO");
	case m: int =>
		return m;
	};
};

// Evaluates a datetime's second of the minute
export fn sec(dt: *datetime) int = {
	match (dt.time.sec) {
	case void =>
		abort("TODO");
	case s: int =>
		return s;
	};
};

// Evaluates a datetime's nanosecond of the second
export fn nsec(dt: *datetime) int = {
	match (dt.time.nsec) {
	case void =>
		abort("TODO");
	case n: int =>
		return n;
	};
};


// A contextual span of time in the proleptic Gregorian calendar.
// Used for calendar arithmetic.
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
	nanoseconds: int,
};

// Hops along the calendar from a moment, according to the given periods
// sequencially, consulting period's units from largest to smallest.
//
// 	// m := 1999-05-13 12:30:45
// 	datetime::hop(m, datetime::period {
// 		years  = 22, // 2021-01-01 00:00:00
// 		months = -1, // 2020-11-01 00:00:00
// 		days   = -4, // 2020-10-27 00:00:00
// 	});
//
export fn hop(m: chrono::moment, pp: period...) chrono::moment = {
	// TODO
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];
	};
	return m;
};

// Adds a calindrical period of time to a moment, largest units first.
// Tries to conserve relative distance from cyclical points on the calendar.
//
// 	// m := 1999-05-13 12:30:45
// 	datetime::hop(m, datetime::period {
// 		years  = 22, // 2021-05-13 00:00:00
// 		months = -1, // 2021-04-13 00:00:00
// 		days   = -4, // 2020-04-09 00:00:00
// 	});
//
// When units overflow, such as when adding a month to Jan 31st inaccurately
// results to Feb 31th, the flag is consulted on how to handle this.
//
// TODO:
// How to handle overflows and predictability with cal-arithm in general?
export fn add(m: chrono::moment, flag: int, pp: period...) chrono::moment = {
	// TODO
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];
	};
	return m;
};

// Specifies behaviour during calendar arithmetic
export type calculus = enum int {
	LOGICAL,
	PHYSICAL,
};
