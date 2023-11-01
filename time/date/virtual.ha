// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;
use time::chrono;

// A [[virtual]] does not have enough information to create a valid [[date]].
export type insufficient = !void;

// A virtual date; a [[date]] wrapper interface, which represents a date of
// uncertain validity. Its fields need not be valid observed chronological
// values. It is meant as an intermediary container for date information to be
// resolved with the [[realize]] function.
//
// Unlike [[date]], a virtual's fields are meant to be treated as public and
// mutable. The embedded [[time::instant]] and [[time::chrono::locality]] fields
// (.sec .nsec .loc) are considered meaningless. Behaviour with the observer
// functions is undefined.
//
// This can be used to safely construct a new [[date]] piece-by-piece. Start
// with [[newvirtual]], then collect enough date/time information incrementally
// by direct field assignments and/or with [[parse]]. Finish with [[realize]].
//
// 	let v = date::newvirtual();
// 	v.vloc = time::chrono::UTC;
// 	v.zoff = 0;
// 	date::parse(&v, "Date: %Y-%m-%d", "Date: 2038-01-19")!;
// 	v.hour = 03;
// 	v.minute = 14;
// 	v.second = 07;
// 	v.nanosecond = 0;
// 	let d = date::realize(v)!;
//
export type virtual = struct {
	date,
	// virtual's locality
	vloc:     (void | chrono::locality),
	// locality name
	locname:  (void | str),
	// zone offset
	zoff:     (void | time::duration),
	// zone abbreviation
	zabbr:    (void | str),
	// hour of 12 hour clock
	halfhour: (void | int),
	// AM/PM (false/true)
	ampm:     (void | bool),
};

// Creates a new [[virtual]]. All its fields are voided or nulled appropriately.
export fn newvirtual() virtual = virtual {
	sec         = 0,
	nsec        = 0,
	loc         = chrono::UTC,
	zone        = null,
	daydate     = void,
	daytime     = void,

	era         = void,
	year        = void,
	month       = void,
	day         = void,
	yearday     = void,
	isoweekyear = void,
	isoweek     = void,
	week        = void,
	sundayweek  = void,
	weekday     = void,

	hour        = void,
	minute      = void,
	second      = void,
	nanosecond  = void,

	vloc        = void,
	locname     = void,
	zoff        = void,
	zabbr       = void,
	halfhour    = void,
	ampm        = void,
};

// Realizes a valid [[date]] from a [[virtual]], or fails appropriately.
// Four values require determination. Each has various determination strategies,
// each of which use a certain set of non-void fields from the given virtual.
// The following determination strategies will be attempted in order.
//
// Field sets for determining the daydate:
//
// 1. daydate
// 2. year, month, day
// 3. year, yearday
// 4. year, week, weekday
// 5. isoweekyear, isoweek, weekday
//
// Field sets for determining the time-of-day:
//
// 1. daytime
// 2. hour, minute, second, nanosecond
//
// Field sets for determining the zone offset:
//
// 1. zoff
//
// Field sets for determining the [[time::chrono::locality]]:
//
// 1. vloc
// 2. locname
//         This is compared to each provided locality's 'name' field,
//         or "UTC" if none are provided. The first match is used.
// 3. (none)
//         Defaults to [[time::chrono::UTC]].
//
// If for any of these values no determination strategy could be attempted,
// [[insufficient]] is returned. If the resultant date is invalid,
// [[invalid]] is returned.
export fn realize(
	v: virtual,
	locs: chrono::locality...
) (date | insufficient | invalid) = {
	// determine .daydate
	if (v.daydate is i64) {
		void;
	} else if (
		v.year is int &&
		v.month is int &&
		v.day is int
	) {
		v.daydate = calc_daydate__ymd(
			v.year as int,
			v.month as int,
			v.day as int,
		)?;
	} else if (
		v.year is int &&
		v.yearday is int
	) {
		v.daydate = calc_daydate__yd(
			v.year as int,
			v.yearday as int,
		)?;
	} else if (
		v.year is int &&
		v.week is int &&
		v.weekday is int
	) {
		v.daydate = calc_daydate__ywd(
			v.year as int,
			v.week as int,
			v.weekday as int,
		)?;
	} else if (false) {
		// TODO: calendar.ha: calc_daydate__isoywd()
		void;
	} else {
		// cannot deduce daydate
		return insufficient;
	};

	// determine .daytime
	if (v.daytime is time::duration) {
		void;
	} else {
		const hour = if (v.hour is int) {
			yield v.hour as int;
		} else if (v.halfhour is int && v.ampm is bool) {
			const hr = v.halfhour as int;
			const pm = v.ampm as bool;
			yield if (pm) hr * 2 else hr;
		} else {
			return insufficient;
		};

		if (
			v.minute is int &&
			v.second is int &&
			v.nanosecond is int
		) {
			v.daytime = calc_daytime__hmsn(
				hour,
				v.minute as int,
				v.second as int,
				v.nanosecond as int,
			)?;
		} else {
			return insufficient;
		};
	};

	// determine zone offset
	if (v.zoff is time::duration) {
		void;
	} else {
		return insufficient;
	};

	// determine .loc (defaults to time::chrono::UTC)
	if (v.vloc is chrono::locality) {
		v.loc = v.vloc as chrono::locality;
	} else if (v.locname is str) {
		v.loc = chrono::UTC;
		for (let i = 0z; i < len(locs); i += 1) {
			const loc = locs[i];
			if (loc.name == v.locname as str) {
				v.loc = loc;
				break;
			};
		};
	};

	// determine .sec, .nsec
	const d = from_moment(chrono::from_datetime(
		v.loc,
		v.zoff as time::duration,
		v.daydate as i64,
		v.daytime as time::duration,
	));

	// verify zone offset
	const z = chrono::mzone(&d);
	if (z.zoff != v.zoff as time::duration) {
		return invalid;
	};

	return d;
};
