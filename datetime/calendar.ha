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

// Calculates a moment's number of days since the calendar epoch 0001-01-01
export fn epochal(dt: *datetime) int = {
	match (dt.date.epochal) {
	case void =>
		abort("TODO");
	case e: int =>
		return e;
	};
};

// Calculates a moment's era
export fn era(dt: *datetime) int = {
	if (epochal(dt) >= EPOCH_COMMONERA) {
		dt.date.era = 1; // CE, Common Era
	} else {
		dt.date.era = 0; // BCE, Before Common Era
	};
	const a = match (dt.date.era) {
	case void =>
		abort("TODO");
	case a: int =>
		yield a;
	};
	return a;
};

// Calculates a moment's year
export fn year(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's month
export fn month(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's day of the month
export fn day(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's ISO week calendar year
export fn isoweekyear(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's ISO week
export fn isoweek(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's Gregorian week
export fn week(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's day of the week
export fn weekday(dt: *datetime) int = {
	return 0; // TODO
};

// Calculates a moment's ordinal day of the year
export fn yearday(dt: *datetime) int = {
	return 0; // TODO
};

//
// time-like
//

// Calculates a moment's hour of the day
export fn hour(dt: *datetime) int = {
	match (dt.time.hour) {
	case void =>
		abort("TODO");
	case h: int =>
		return h;
	};
};

// Calculates a moment's minute of the hour
export fn min(dt: *datetime) int = {
	match (dt.time.min) {
	case void =>
		abort("TODO");
	case m: int =>
		return m;
	};
};

// Calculates a moment's second of the minute
export fn sec(dt: *datetime) int = {
	match (dt.time.sec) {
	case void =>
		abort("TODO");
	case s: int =>
		return s;
	};
};

// Calculates a moment's nanosecond of the second
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
