// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;
use time::chrono;

// A [[virtual]] does not have enough information to create a valid [[date]].
export type insufficient = !lack; // TODO: drop alias workaround

export type lack = enum u8 {
	DAYDATE = 1 << 0, // could not infer daydate
	DAYTIME = 1 << 1, // could not infer time-of-day
	ZOFF = 1 << 2,    // could not infer zone offset
};

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
	// virtual's timescalar second
	vsec:     (void | i64),
	// virtual's nanosecond of timescalar second
	vnsec:    (void | i64),
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

	vsec        = void,
	vnsec       = void,
	vloc        = void,
	locname     = void,
	zoff        = void,
	zabbr       = void,
	halfhour    = void,
	ampm        = void,
};

// Realizes a valid [[date]] from a [[virtual]], or fails appropriately.
//
// The virtual must hold enough valid date information to be able to calculate
// values for the resulting date. A valid combination of its fields must be
// "filled-in" (hold numerical, non-void values). For example:
//
// 	let v = date::newvirtual();
// 	v.locname = "Europe/Amsterdam";
// 	v.zoff = 1 * time::HOUR;
// 	date::parse(&v, // fills-in .year .month .day
// 		"Date: %Y-%m-%d", "Date: 2038-01-19")!;
// 	v.hour = 4;
// 	v.minute = 14;
// 	v.second = 7;
// 	v.nanosecond = 0;
// 	let d = date::realize(v, time::chrono::tz("Europe/Amsterdam")!)!;
//
// This function consults the fields of the given virtual using a predictable
// procedure. In calculating a date, it attempts to calculate values for empty
// fields using sets of other filled-in fields (dependencies), in a order
// described below.
//
// The resultant date depends on a locality and instant.
//
// The locality ([[time::chrono::locality]]) depends on:
//
// - .vloc
// - .locname : This is compared to the .name field of each locality
//   provided via the locs parameter, or "UTC" if none are provided.
//   The first matching locality is used.
// - (nothing) : Defaults to [[time::chrono::UTC]].
//
// The instant ([[time::instant]]) depends on:
//
// - .vsec, .vnsec
// - .daydate, .daytime, .zoff
//
// An empty .daydate depends on:
//
// - .year, .month, .day
// - .year, .yearday
// - .year, .week, .weekday
// - .isoweekyear, .isoweek, .weekday
//
// An empty .daytime depends on:
//
// - .hour, .minute, .second, .nanosecond
//
// If none of the possible combinations of fields were filled-in,
// [[insufficient]] is returned. If after calculation the resultant date is
// invalid, [[invalid]] is returned.
export fn realize(
	v: virtual,
	locs: chrono::locality...
) (date | insufficient | invalid) = {
	let lacking = 0u8;

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

	// try using .vsec .vnsec
	if (v.vsec is i64 && v.vnsec is i64) {
		return from_instant(
			v.loc,
			time::instant{
				sec = v.vsec as i64,
				nsec = v.vnsec as i64,
			},
		);
	};

	// try using .daydate, .daytime, .zoff

	// determine zone offset
	if (v.zoff is i64) {
		void;
	} else {
		lacking |= insufficient::ZOFF;
	};

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
		lacking |= insufficient::DAYDATE;
	};

	// determine .daytime
	if (v.daytime is i64) {
		void;
	} else :daytime {
		const hour =
			if (v.hour is int) {
				yield v.hour as int;
			} else if (v.halfhour is int && v.ampm is bool) {
				const hr = v.halfhour as int;
				const pm = v.ampm as bool;
				yield if (pm) hr * 2 else hr;
			} else {
				lacking |= insufficient::DAYTIME;
				yield :daytime;
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
			lacking |= insufficient::DAYTIME;
		};
	};

	if (lacking != 0u8) {
		return lacking: insufficient;
	};

	// determine .sec, .nsec
	const d = from_moment(chrono::from_datetime(
		v.loc,
		v.zoff as time::duration,
		v.daydate as i64,
		v.daytime as i64,
	));

	// verify zone offset
	const z = chrono::ozone(&d);
	if (z.zoff != v.zoff as time::duration) {
		return invalid;
	};

	return d;
};
