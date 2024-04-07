// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;
use time::chrono;

// Specifies the behaviour of [[reckon]] when doing chronological arithmetic.
//
// The FLOOR, CEIL, HOP, and FOLD specifies how to resolve sub-significant
// overflows -- when a field's change in value causes any sub-significant
// field's range to shrink below its current value and become invalid. For
// example, adding 1 month to January 31st results in February 31st, a date with
// an unresolved day field, since February permits only 28 or 29 days.
export type rflag = enum uint {
	// The default behaviour. Equivalent to CEIL.
	DEFAULT = 0,

	// Apply units in reverse order, from least to most significant.
	REVSIG = 1 << 0,

	// When a sub-significant overflow occurs, the unresolved field is set
	// to its minimum valid value.
	//
	//     Feb 31 -> Feb 01
	//     Aug 64 -> Aug 01
	FLOOR = 1 << 1,

	// When a sub-significant overflow occurs, the unresolved field is set
	// to its maximum valid value.
	//
	//     Feb 31 -> Feb 28 / Feb 29   (leap year dependent)
	//     Aug 64 -> Aug 31
	CEIL = 1 << 2,

	// When a sub-significant overflow occurs, the unresolved field is set
	// to its new minimum valid value after the next super-significant field
	// increments by one.
	//
	//     Feb 31 -> Mar 01
	//     Aug 64 -> Sep 01
	HOP = 1 << 3,

	// When a sub-significant overflow occurs, the unresolved field's
	// maximum valid value is subtracted from it's current value, and the
	// next super-significant field increments by one. This process repeats
	// until the unresolved field's value becomes valid (falls in range).
	//
	//     Feb 31 -> Mar 03 / Mar 02   (leap year dependent)
	//     Aug 64 -> Sep 33 -> Oct 03
	FOLD = 1 << 4,
};

// Reckons from a given [[date]] to a new one, via a given set of [[period]]s.
// This is a chronological arithmetic operation. Each period is reckoned
// independently in succession, applying (adding) their units from most to least
// significant.
//
// The [[rflag]] parameter handles field overflows and other behaviours.
// The [[zflag]] parameter affects the final result. Example:
//
// 	// 2000-02-29 00:00:00.000000000 -1100 -11 Pacific/Apia
// 	let a = date::new(chrono::tz("Pacific/Apia")!, -11 * time::HOUR,
// 		2000,  2, 29)!;
//
// 	let b = date::reckon(a,    // starts as: 2000-Feb-29 00:00 -1100
// 		date::zflag::GAP_END,
// 		date::rflag::DEFAULT,
// 		date::period {
// 			years  = 11, // becomes: 2011-Feb-28 00:00 -1100
// 			months = 10, // becomes: 2011-Dec-28 00:00 -1100
// 			days   =  1, // becomes: 2011-Dec-29 00:00 -1100
// 			hours  = 36, // becomes: 2011-Dec-30 12:00 -1100
// 		},
// 		// In Samoa, Apia, the day 2011-Dec-30 was skipped entirely.
// 		// Thus, after applying date::zflag::GAP_END for adjustment,
// 		// we arrive at the final date, time, and zone-offset:
// 		// 2011-12-31 00:00:00.000000000 +1400 +14 Pacific/Apia
// 	);
//
// See [[add]].
export fn reckon(
	d: date,
	zoff: (time::duration | zflag),
	rf: rflag,
	ps: period...
) (date | invalid | zfunresolved) = {
	let r = newvirtual(); // our reckoner
	r.vloc       = d.loc;
	r.zoff       = zoff;
	r.year       = _year(&d);
	r.month      = _month(&d);
	r.day        = _day(&d);
	r.hour       = _hour(&d);
	r.minute     = _minute(&d);
	r.second     = _second(&d);
	r.nanosecond = _nanosecond(&d);

	if (rf == rflag::DEFAULT) {
		rf |= rflag::CEIL;
	};

	for (let p .. ps) if (rf & rflag::REVSIG == 0) {
		const fold = rflag::FOLD;

		r.year = r.year as int + p.years: int;
		reckon_days(&r, 0, rf); // bubble up potential Feb 29 overflow

		reckon_months(&r, p.months);
		reckon_days(&r,   0, rf); // bubble up potential overflows

		reckon_days(&r, p.weeks * 7, fold);
		reckon_days(&r, p.days,      fold);

		// TODO: These functions aren't aware of top-down overflows.
		// Handle overflows (e.g. [[zone]] changes).
		reckon_hours(&r,       p.hours,       fold);
		reckon_minutes(&r,     p.minutes,     fold);
		reckon_seconds(&r,     p.seconds,     fold);
		reckon_nanoseconds(&r, p.nanoseconds, fold);
	} else {
		const fold = rflag::FOLD | rflag::REVSIG;

		reckon_nanoseconds(&r, p.nanoseconds, fold);
		reckon_seconds(&r,     p.seconds,     fold);
		reckon_minutes(&r,     p.minutes,     fold);
		reckon_hours(&r,       p.hours,       fold);
		reckon_days(&r,        p.days,        fold);
		reckon_days(&r,        p.weeks * 7,   fold);

		reckon_months(&r, p.months);
		reckon_days(&r,   0, rf); // bubble up potential overflows

		r.year = r.year as int + p.years: int;
		reckon_days(&r, 0, rf); // bubble up potential Feb 29 overflow
	};

	return realize(r) as (date | invalid | zfunresolved);
};

fn reckon_months(r: *virtual, months: i64) void = {
	let year  = r.year  as int;
	let month = r.month as int;

	month += months: int;

	// month overflow
	for (month > 12) {
		month -= 12;
		year  += 1;
	};
	for (month < 1) {
		month += 12;
		year  -= 1;
	};

	r.year  = year;
	r.month = month;
};

fn reckon_days(r: *virtual, days: i64, rf: rflag) void = {
	let year  = r.year  as int;
	let month = r.month as int;
	let day   = r.day   as int;

	day += days: int;

	// day overflow
	let monthdays = calc_days_in_month(year, month);
	for (day > monthdays) {
		if (rf & rflag::FLOOR != 0) {
			day = 1;
		} else if (rf & rflag::CEIL != 0) {
			day = monthdays;
		} else if (rf & rflag::HOP != 0) {
			r.year  = year;
			r.month = month;

			reckon_months(r, 1);

			year  = r.year  as int;
			month = r.month as int;
			day   = 1;
		} else if (rf & rflag::FOLD != 0) {
			r.year  = year;
			r.month = month;

			reckon_months(r, 1);

			year   = r.year  as int;
			month  = r.month as int;
			day   -= monthdays;
		};
		monthdays = calc_days_in_month(year, month);
	};
	for (day < 1) {
		r.year  = year;
		r.month = month;

		reckon_months(r, -1);

		year   = r.year  as int;
		month  = r.month as int;
		day   += calc_days_in_month(year, month);
	};

	r.year  = year;
	r.month = month;
	r.day   = day;
};

fn reckon_hours(r: *virtual, hours: i64, rf: rflag) void = {
	let hour = r.hour as int;

	hour += hours: int;

	// hour overflow
	for (hour >= 24) {
		reckon_days(r, 1, rf);
		hour -= 24;
	};
	for (hour < 0) {
		reckon_days(r, -1, rf);
		hour += 24;
	};

	r.hour = hour;
};

fn reckon_minutes(r: *virtual, mins: i64, rf: rflag) void = {
	let min = r.minute as int;

	min += mins: int;

	// minute overflow
	for (min >= 60) {
		reckon_hours(r, 1, rf);
		min -= 60;
	};
	for (min < 0) {
		reckon_hours(r, -1, rf);
		min += 60;
	};

	r.minute = min;
};

fn reckon_seconds(r: *virtual, secs: i64, rf: rflag) void = {
	let s = r.second as int;

	s += secs: int;

	// second overflow
	for (s >= 60) {
		reckon_minutes(r, 1, rf);
		s -= 60;
	};
	for (s < 0) {
		reckon_minutes(r, -1, rf);
		s += 60;
	};

	r.second = s;
};

fn reckon_nanoseconds(r: *virtual, nsecs: i64, rf: rflag) void = {
	let ns = r.nanosecond as int;

	ns += nsecs: int;

	// nanosecond overflow
	for (ns >= 1000000000) { // 1E9 nanoseconds (1 second)
		reckon_seconds(r, 1, rf);
		ns -= 1000000000;
	};
	for (ns < 0) {
		reckon_seconds(r, -1, rf);
		ns += 1000000000;
	};

	r.nanosecond = ns;
};

@test fn reckon() void = {
	// no-op period, rflag::CEIL

	let p = period { ... };

	let a = new(chrono::UTC, 0)!;
	let r = reckon(a, zflag::CONTIG, 0, p)!;
	assert(chrono::simultaneous(&a, &r)!, "01. incorrect result");

	let a = new(chrono::UTC, 0,  2019, 12, 27,  21,  7,  8,         0)!;
	let r = reckon(a, zflag::CONTIG, 0, p)!;
	assert(chrono::simultaneous(&a, &r)!, "02. incorrect result");

	let a = new(chrono::UTC, 0,  1970,  1,  1,   0,  0,  0,         0)!;
	let r = reckon(a, zflag::CONTIG, 0, p)!;
	assert(chrono::simultaneous(&a, &r)!, "03. incorrect result");

	// generic periods, rflag::CEIL

	let a = new(chrono::UTC, 0,  2019, 12, 27,  21,  7,  8,         0)!;

	let r = reckon(a, zflag::CONTIG, 0, period {
		years       = 1,
		months      = 1,
		days        = 1,
		hours       = 1,
		minutes     = 1,
		seconds     = 1,
		nanoseconds = 1,
		...
	})!;
	let b = new(chrono::UTC, 0,  2021,  1, 28,  22,  8,  9,         1)!;
	assert(chrono::simultaneous(&b, &r)!, "04. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, period {
		years       = -1,
		months      = -1,
		days        = -1,
		hours       = -1,
		minutes     = -1,
		seconds     = -1,
		nanoseconds = -1,
		...
	})!;
	let b = new(chrono::UTC, 0,  2018, 11, 26,  20,  6,  6, 999999999)!;
	assert(chrono::simultaneous(&b, &r)!, "05. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, period {
		years       = 100,
		months      = 100,
		days        = 100,
		hours       = 100,
		minutes     = 100,
		seconds     = 100,
		nanoseconds = 100,
		...
	})!;
	let b = new(chrono::UTC, 0,  2128,  8, 10,   2, 48, 48,       100)!;
	assert(chrono::simultaneous(&b, &r)!, "06. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, period {
		years       = -100,
		months      = -100,
		days        = -100,
		hours       = -100,
		minutes     = -100,
		seconds     = -100,
		nanoseconds = -100,
		...
	})!;
	let b = new(chrono::UTC, 0,  1911,  5, 15,  15, 25, 27, 999999900)!;
	assert(chrono::simultaneous(&b, &r)!, "07. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, period {
		weeks = 100,
		...
	})!;
	let b = new(chrono::UTC, 0,  2021, 11, 26,  21,  7,  8,         0)!;
	assert(chrono::simultaneous(&b, &r)!, "08. incorrect result");

	// rflag, February 29 overflows

	let a = new(chrono::UTC, 0,  2000,  1, 31)!; // leap year
	let p = period { months = 1, ... };

	let r = reckon(a, zflag::CONTIG, rflag::FLOOR, p)!;
	let b = new(chrono::UTC, 0,  2000,  2,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "09. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::CEIL, p)!;
	let b = new(chrono::UTC, 0,  2000,  2, 29)!;
	assert(chrono::simultaneous(&b, &r)!, "10. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::HOP, p)!;
	let b = new(chrono::UTC, 0,  2000,  3,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "11. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::FOLD, p)!;
	let b = new(chrono::UTC, 0,  2000,  3,  2)!;
	assert(chrono::simultaneous(&b, &r)!, "12. incorrect result");

	// rflag, February 28 overflows

	let a = new(chrono::UTC, 0,  2000,  1, 31)!; // leap year
	let p = period { years = 1, months = 1, ... };

	let r = reckon(a, zflag::CONTIG, rflag::FLOOR, p)!;
	let b = new(chrono::UTC, 0,  2001,  2,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "13. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::CEIL, p)!;
	let b = new(chrono::UTC, 0,  2001,  2, 28)!;
	assert(chrono::simultaneous(&b, &r)!, "14. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::HOP, p)!;
	let b = new(chrono::UTC, 0,  2001,  3,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "15. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::FOLD, p)!;
	let b = new(chrono::UTC, 0,  2001,  3,  3)!;
	assert(chrono::simultaneous(&b, &r)!, "16. incorrect result");

	// multiple periods

	let a = new(chrono::UTC, 0,  2000, 12, 31)!;
	let ps = [
		period { years =  1, months =  1, days =  1, ... },
		period { years = -1, months = -1, days = -1, ... },
		period { years = -1, months = -1, days = -1, ... },
		period { years =  1, months =  1, days =  1, ... },
		period { hours =  1, minutes =  1, seconds =  1, ... },
		period { hours = -1, minutes = -1, seconds = -1, ... },
		period { hours = -1, minutes = -1, seconds = -1, ... },
		period { hours =  1, minutes =  1, seconds =  1, ... },
	];

	let r = reckon(a, zflag::CONTIG, 0, ps[..1]...)!;
	let b = new(chrono::UTC, 0,  2002,  2,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "17. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..2]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 31)!;
	assert(chrono::simultaneous(&b, &r)!, "18. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..3]...)!;
	let b = new(chrono::UTC, 0,  1999, 11, 29)!;
	assert(chrono::simultaneous(&b, &r)!, "19. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..4]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 30)!;
	assert(chrono::simultaneous(&b, &r)!, "20. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..5]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 30,   1,  1,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "21. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..6]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 30)!;
	assert(chrono::simultaneous(&b, &r)!, "22. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..7]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 29,  22, 58, 59)!;
	assert(chrono::simultaneous(&b, &r)!, "23. incorrect result");

	let r = reckon(a, zflag::CONTIG, 0, ps[..8]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 30)!;
	assert(chrono::simultaneous(&b, &r)!, "24. incorrect result");

	// multiple periods, rflag::REVSIG

	let a = new(chrono::UTC, 0,  2000, 12, 31)!;
	let ps = [
		period { years =  1, months =  1, days =  1, ... },
		period { years = -1, months = -1, days = -1, ... },
		period { years = -1, months = -1, days = -1, ... },
		period { years =  1, months =  1, days =  1, ... },
		period { hours =  1, minutes =  1, seconds =  1, ... },
		period { hours = -1, minutes = -1, seconds = -1, ... },
		period { hours = -1, minutes = -1, seconds = -1, ... },
		period { hours =  1, minutes =  1, seconds =  1, ... },
	];

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..1]...)!;
	let b = new(chrono::UTC, 0,  2002,  2,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "25. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..2]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 31)!;
	assert(chrono::simultaneous(&b, &r)!, "26. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..3]...)!;
	let b = new(chrono::UTC, 0,  1999, 11, 30)!;
	assert(chrono::simultaneous(&b, &r)!, "27. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..4]...)!;
	let b = new(chrono::UTC, 0,  2001,  1,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "28. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..5]...)!;
	let b = new(chrono::UTC, 0,  2001,  1,  1,   1,  1,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "29. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..6]...)!;
	let b = new(chrono::UTC, 0,  2001,  1,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "30. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..7]...)!;
	let b = new(chrono::UTC, 0,  2000, 12, 31,  22, 58, 59)!;
	assert(chrono::simultaneous(&b, &r)!, "31. incorrect result");

	let r = reckon(a, zflag::CONTIG, rflag::REVSIG, ps[..8]...)!;
	let b = new(chrono::UTC, 0,  2001,  1,  1)!;
	assert(chrono::simultaneous(&b, &r)!, "32. incorrect result");

	return;
};
