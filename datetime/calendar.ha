use time;
use time::chrono;


// The epoch of the Julian Day Number
export def EPOCH_JULIAN: i64 = -2440588;

// The epoch of the Common Era
export def EPOCH_COMMONERA: i64 = -719164;


export fn conv_datetime_moment(dt: datetime) chrono::moment = {
	const d = conv_localdate_epochal(dt.date);
	const t = conv_localtime_time(dt.time);
	const m = chrono::moment {
		date = d,
		time = t,
		loc = dt.loc,
	};
	return m;
};

export fn conv_moment_datetime(m: chrono::moment) datetime = {
	const ld = conv_epochal_localdate(m.date);
	const lt = conv_time_localtime(m.time);
	const dt = datetime {
		date = ld,
		time = lt,
		loc = m.loc,
	};
	return dt;
};


//
// date-like
//

// Calculates a moment's number of days since the calendar epoch 0001-01-01
export fn epocal(m: chrono::moment) int = {
	return (EPOCH_COMMONERA + m.date): int;
};

// Calculates a moment's era
export fn era(m: chrono::moment) int = {
	if (m.date > EPOCH_COMMONERA) {
		return 0; // CE, Common Era
	} else {
		return -1; // BCE, Before Common Era
	};
};

// Calculates a moment's year
export fn year(m: chrono::moment) int = {
	const ld = conv_epochal_localdate(m.date);
	return ld.year as int;
};

// Calculates a moment's month
export fn month(m: chrono::moment) int = {
	const ld = conv_epochal_localdate(m.date);
	return ld.month as int;
};

// Calculates a moment's day of the month
export fn day(m: chrono::moment) int = {
	const ld = conv_epochal_localdate(m.date);
	return ld.day as int;
};

// Calculates a moment's ISO week calendar year
export fn weekyear(m: chrono::moment) int = {
	// TODO
	return 0;
};

// Calculates a moment's ISO week
export fn week(m: chrono::moment) int = {
	// TODO
	return 0;
};

// Calculates a moment's ordinal day of the year
export fn yearday(m: chrono::moment) int = {
	// TODO
	return 0;
};

//
// time-like
//

// Calculates a moment's hour of the day
export fn hour(m: chrono::moment) int = {
	return (m.time / time::HOUR): int;
};

// Calculates a moment's minute of the hour
export fn min(m: chrono::moment) int = {
	return ((m.time / time::MINUTE) % 60): int;
};

// Calculates a moment's second of the minute
export fn sec(m: chrono::moment) int = {
	return ((m.time / time::SECOND) % 60): int;
};

// Calculates a moment's nanosecond of the second
export fn nsec(m: chrono::moment) int = {
	return (m.time % time::SECOND): int;
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

export type calculus = enum int {
	LOGICAL,
	PHYSICAL,
};
