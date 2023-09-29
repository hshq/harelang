// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Represents a span of time in the Gregorian chronology, using nominal units of
// time. Used for chronological arithmetic.
export type period = struct {
	years: i64,
	months: i64,
	weeks: i64,
	days: i64,
	hours: i64,
	minutes: i64,
	seconds: i64,
	nanoseconds: i64,
};

// Returns true if two [[period]]s are numerically equal, false otherwise.
export fn peq(pa: period, pb: period) bool = {
	return (
		pa.years          == pb.years
		&& pa.months      == pb.months
		&& pa.weeks       == pb.weeks
		&& pa.days        == pb.days
		&& pa.hours       == pb.hours
		&& pa.minutes     == pb.minutes
		&& pa.seconds     == pb.seconds
		&& pa.nanoseconds == pb.nanoseconds
	);
};

// Returns the sum [[period]] of a set of periods.
export fn sum(ps: period...) period = {
	let p = period { ... };
	for (let i = 0z; i < len(ps); i += 1) {
		p.years       += ps[i].years;
		p.months      += ps[i].months;
		p.weeks       += ps[i].weeks;
		p.days        += ps[i].days;
		p.hours       += ps[i].hours;
		p.minutes     += ps[i].minutes;
		p.seconds     += ps[i].seconds;
		p.nanoseconds += ps[i].nanoseconds;
	};
	return p;
};

// Returns a [[period]] with its fields negated.
export fn neg(p: period) period = period {
	years       = -p.years,
	months      = -p.months,
	weeks       = -p.weeks,
	days        = -p.days,
	hours       = -p.hours,
	minutes     = -p.minutes,
	seconds     = -p.seconds,
	nanoseconds = -p.nanoseconds,
};

// Returns a [[period]] with its fields made absolute and positive.
export fn abs(p: period) period = period {
	years       = if (p.years < 0)       -p.years       else p.years,
	months      = if (p.months < 0)      -p.months      else p.months,
	weeks       = if (p.weeks < 0)       -p.weeks       else p.weeks,
	days        = if (p.days < 0)        -p.days        else p.days,
	hours       = if (p.hours < 0)       -p.hours       else p.hours,
	minutes     = if (p.minutes < 0)     -p.minutes     else p.minutes,
	seconds     = if (p.seconds < 0)     -p.seconds     else p.seconds,
	nanoseconds = if (p.nanoseconds < 0) -p.nanoseconds else p.nanoseconds,
};
