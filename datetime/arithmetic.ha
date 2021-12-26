use time::chrono;

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
	nanoseconds: int,
};

// Specifies behaviour during calendar arithmetic
export type calculus = enum int {
	LOGICAL,
	PHYSICAL,
};

// Calculates the difference between two datetimes
export fn diff(a: datetime, b: datetime) period = {
	// TODO
	return period { ... };
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
	// TODO
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];
	};
	return dt;
};

// Adds a calindrical period of time to a datetime, largest units first.
// Tries to conserve relative distance from cyclical points on the calendar.
//
// 	let dt = ... // 1999-05-13 12:30:45
// 	datetime::hop(dt, datetime::calculus::LOGICAL, datetime::period {
// 		years  = 22, // 2021-05-13 00:00:00
// 		months = -1, // 2021-04-13 00:00:00
// 		days   = -4, // 2020-04-09 00:00:00
// 	});
//
// When units overflow, such as when adding a month to Jan 31st would
// erroneously result in Feb 31th, the flag is consulted on how to handle this.
//
// TODO:
// How to handle overflows and predictability with cal-arithm in general?
export fn add(dt: datetime, flag: int, pp: period...) datetime = {
	// TODO
	for (let i = 0z; i < len(pp); i += 1) {
		const p = pp[i];
	};
	return dt;
};
