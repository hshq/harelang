// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sort;
use time;
use time::chrono;

// Flags for resolving an absent zone-offset. Handles timezone transitions.
//
// The [[realize]] function, as well as other date creation functions (like
// [[new]], [[truncate]], [[reckon]]...) accept zflags. If zflags are provided,
// these functions normally calculate an intermediate date with a best-guess
// numerical zone-offset. This intermediate date can be [[invalid]] if it falls
// within the observed overlap or gap of a timezone transition, where such dates
// are ambiguous or nonexistent. In this case, the provided zflags are
// consulted, and a final calculation takes place before the final resultant
// date (or [[zfunresolved]]) is returned.
//
// Timezone transitions create gaps and overlaps, the two causes of [[invalid]]
// intermediate dates. Passing one "GAP_" and one "LAP_" flag covers both cases.
//
// 	let zf = date::zflag::LAP_EARLY | date::zflag::GAP_END;
// 	date::new(loc, zf, fields...)!; // will never return [[zfunresolved]]
//
// Note that usage of "GAP_" flags will cause the resultant date to be different
// to what is originally specified if the intermediate date falls within a gap.
// Flags with greater value take precedent.
//
// The following figures exist to help understand the effect of these flags.
//
// 	Fig A                    2000 October 29th
// 	                              -1 hour
//
// 	                                 f=02:30+0200
// 	                                 g=02:30+0100
// 	                             lp  | lq
// 	                 +0200        |  |  |       +0100
// 	  Observed time: 00    01    02  | 03    04    05
// 	      Amsterdam:  |-----|-----|==*==|-----|-----|
// 	                  .     .     .\ :: |.     .
// 	                  .     .     . \: :| .     .
// 	                  .     .     .  :  :  .     .
// 	                  .     .     .  :\ |:  .     .
// 	                  .     .     .  : \| :  .     .
// 	            UTC:  |-----|-----|--*--|--*--|-----|
// 	Contiguous time: 22    23    00  | 01  | 02    03
// 	                                 |  |  |
// 	                                 a tx  b
//
// Fig A -- A backjump timezone transition in the Europe/Amsterdam locality.
// The transition is marked by "tx". There is an overlap in the chronology,
// marked by "lp" and "lq". The specified local time 02:30 falls within the
// observed overlap, and so has two valid zone-offsets and can be observed
// twice, as dates "f" and "g". When localized to UTC, these two observations
// correspond to UTC dates "a" and "b" respectively.
//
// 	Fig B                     2000 March 26th
// 	                              +1 hour
//
// 	                                 f~02:30+!!!!
// 	                             gp  | gq
// 	                 +0100        |  |  |       +0200
// 	  Observed time: 00    01    02  | 03    04    05
// 	      Amsterdam:  |-----|-----|  *  |-----|-----|
// 	                  .     .     |    /     .     .
// 	                  .     .     |   /     .     .
// 	                  .     .     |  /     .     .
// 	                  .     .     | /     .     .
// 	                  .     .     |/     .     .
// 	            UTC:  |-----|-----|-----|-----|-----|
// 	Contiguous time: 23    00    01    02    03    04
// 	                              |
// 	                             tx
//
// Fig B -- A forejump timezone transition in the Europe/Amsterdam locality.
// The transition is marked by "tx". There is a gap in the chronology, marked by
// "gp" and "gq". The specified local time 02:30 falls within the observed gap,
// and so cannot be observed and is [[invalid]].
export type zflag = enum u8 {
	// Assume a contiguous chronology with no observed gaps or overlaps.
	// Upon encountering an observed gap or overlap, fail with [[invalid]].
	// In other words, accept one and only one zone-offset.
	CONTIG    = 0b00000000,

	// Upon encountering an observed overlap, select the earliest possible
	// date (Fig A "f") using the most positive (eastmost) zone-offset.
	LAP_EARLY = 0b00000001,
	// Upon encountering an observed overlap, select the latest possible
	// date (Fig A "g") using the most negative (westmost) zone-offset.
	LAP_LATE  = 0b00000010,

	// Upon encountering an observed gap, disregard the specified date and
	// select the date at the start boundary of the observed gap (Fig B
	// "gp"), corresponding to the contiguous time just before the
	// transition (Fig B "tx").
	GAP_START = 0b00000100,
	// Upon encountering an observed gap, disregard the specified date and
	// select the date at the end boundary of the observed gap (Fig B "gq"),
	// corresponding to the contiguous time at the transition (Fig B "tx").
	GAP_END   = 0b00001000,
};

// Failed to resolve an absent zone-offset. The provided [[zflag]]s failed to
// account for some timezone effect and could not produce a valid zone-offset.
// A false value signifies the occurence of a timezone transition gap.
// A true value signifies the occurence of a timezone transition overlap.
export type zfunresolved = !bool;

// A [[virtual]] date does not have enough information from which to create a
// valid [[date]].
export type insufficient = !lack; // TODO: drop alias workaround

export type lack = enum u8 {
	LOCALITY = 1 << 0, // could not deduce locality
	DAYDATE = 1 << 1,  // could not deduce daydate
	DAYTIME = 1 << 2,  // could not deduce time-of-day
	ZOFF = 1 << 3,     // could not deduce zone offset
};

// A virtual date; a [[date]] wrapper interface, which represents a date of
// uncertain validity. Its fields need not be valid observed chronological
// values. It is meant as an intermediary container for date information to be
// resolved with the [[realize]] function.
//
// Unlike [[date]], a virtual date's fields are meant to be treated as public
// and mutable. The embedded [[time::instant]] and [[time::chrono::locality]]
// fields (.sec .nsec .loc) are considered meaningless. Behaviour with the
// observer functions is undefined.
//
// This can be used to safely construct a new [[date]] piece-by-piece. Start
// with [[newvirtual]], then collect enough date/time information incrementally
// by direct field assignments and/or with [[parse]]. Finish with [[realize]].
//
// 	let v = date::newvirtual();
// 	v.vloc = chrono::tz("Europe/Amsterdam")!;
// 	v.zoff = date::zflag::LAP_EARLY | date::zflag::GAP_END;
// 	date::parse(&v, "Date: %Y-%m-%d", "Date: 2000-01-02")!;
// 	v.hour = 15;
// 	v.minute = 4;
// 	v.second = 5;
// 	v.nanosecond = 600000000;
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
	zoff:     (void | time::duration | zflag),
	// zone abbreviation
	zabbr:    (void | str),
	// all but the last two digits of the year
	century:  (void | int),
	// the last two digits of the year
	year100:  (void | int),
	// hour of 12 hour clock
	hour12:   (void | int),
	// AM/PM (false/true)
	ampm:     (void | bool),
};

// Creates a new [[virtual]] date. All its fields are voided or nulled.
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
	century     = void,
	year100     = void,
	hour12      = void,
	ampm        = void,
};

// Realizes a valid [[date]] from a [[virtual]] date, or fails appropriately.
//
// The virtual date must hold enough valid date information to be able to
// calculate values for the resulting date. A valid combination of its fields
// must be "filled-in" (hold numerical, non-void values). For example:
//
// 	let v = date::newvirtual();
// 	v.locname = "Europe/Amsterdam";
// 	v.zoff = date::zflag::LAP_EARLY | date::zflag::GAP_END;
// 	date::parse(&v, // fills-in .year .month .day
// 		"Date: %Y-%m-%d", "Date: 2038-01-19")!;
// 	v.hour = 4;
// 	v.minute = 14;
// 	v.second = 7;
// 	v.nanosecond = 0;
// 	let d = date::realize(v, time::chrono::tz("Europe/Amsterdam")!)!;
//
// This function consults the fields of the given virtual date using a
// predictable procedure, attempting the simplest and most common field
// combinations first. Fields marked below with an asterisk (*), when empty,
// depend on other filled-in field-sets to calculate a new value for itself. The
// order in which these "dependency" field-sets are tried is described below.
//
// The resultant date depends on a locality value and instant value.
//
// The locality ([[time::chrono::locality]]) value depends on:
//
// - .vloc
// - .locname : This is compared to the .name field of each locality
//   provided via the locs parameter, or "UTC" if none are provided.
//   The first matching locality is used.
//
// The instant ([[time::instant]]) value depends on:
//
// - .vsec, .vnsec
// - .daydate*, .daytime*, .zoff
//
// An empty .daydate depends on:
//
// - .year*, .month, .day
// - .year*, .yearday
// - .year*, .week, .weekday
// - .isoweekyear, .isoweek, .weekday
//
// An empty .daytime depends on:
//
// - .hour*, .minute, .second, .nanosecond
//
// An empty .year depends on:
//
// - .century, .year100
//
// An empty .hour depends on:
//
// - .hour12, .ampm
//
// If not enough information was provided, [[insufficient]] is returned.
// If invalid information was provided, [[invalid]] is returned.
// Any [[zflag]]s assigned to the .zoff field affect the final result.
export fn realize(
	v: virtual,
	locs: chrono::locality...
) (date | insufficient | invalid | zfunresolved) = {
	match (v.zoff) {
	case void =>
		return lack::ZOFF;
	case time::duration =>
		return realize_validzoff(v, locs...);
	case let zf: zflag =>
		let valid_dates = realize_validzoffs(v, locs...)?;
		switch (len(valid_dates)) {
		case 0 =>
			if (0 != zf & zflag::GAP_END) {
				return realize_gapbounds(v).1;
			} else if (0 != zf & zflag::GAP_START) {
				return realize_gapbounds(v).0;
			} else {
				return false: zfunresolved;
			};
		case 1 =>
			return valid_dates[0];
		case =>
			if (0 != zf & zflag::LAP_LATE) {
				return valid_dates[len(valid_dates) - 1];
			} else if (0 != zf & zflag::LAP_EARLY) {
				return valid_dates[0];
			} else {
				return true: zfunresolved;
			};
		};
	};
};

fn realize_validzoff(
	v: virtual,
	locs: chrono::locality...
) (date | insufficient | invalid) = {
	let d = realize_datetimezoff(v, locs...)?;

	// verify zone offset
	if (chrono::ozone(&d).zoff != v.zoff as time::duration) {
		return invalid;
	};

	return d;
};

fn realize_datetimezoff(
	v: virtual,
	locs: chrono::locality...
) (date | insufficient | invalid) = {
	let lacking = 0u8;

	// determine .loc
	if (v.vloc is chrono::locality) {
		v.loc = v.vloc as chrono::locality;
	} else if (v.locname is str) {
		for (let loc .. locs) {
			if (loc.name == v.locname as str) {
				v.loc = loc;
				break;
			};
		};
	} else {
		lacking |= insufficient::LOCALITY;
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
	} else :daydate {
		const year =
			if (v.year is int) {
				yield v.year as int;
			} else if (v.century is int && v.year100 is int) {
				let cc = v.century as int;
				let yy = v.year100 as int;
				if (yy < 0 || yy > 99) {
					return invalid;
				};
				yield cc * 100 + yy;
			} else {
				lacking |= lack::DAYDATE;
				yield :daydate;
			};

		if (
			v.month is int &&
			v.day is int
		) {
			v.daydate = calc_daydate__ymd(
				year,
				v.month as int,
				v.day as int,
			)?;
		} else if (
			v.yearday is int
		) {
			v.daydate = calc_daydate__yd(
				year,
				v.yearday as int,
			)?;
		} else if (
			v.week is int &&
			v.weekday is int
		) {
			v.daydate = calc_daydate__ywd(
				year,
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
	};

	// determine .daytime
	if (v.daytime is i64) {
		void;
	} else :daytime {
		const hour =
			if (v.hour is int) {
				yield v.hour as int;
			} else if (v.hour12 is int && v.ampm is bool) {
				const hr = v.hour12 as int;
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

	return d;
};

fn realize_validzoffs(
	v: virtual,
	locs: chrono::locality...
) ([]date | insufficient | invalid) = {
	// check if only zoff is missing
	v.zoff = 0o0;
	match (realize_validzoff(v, locs...)) {
	case (date | invalid) =>
		void;
	case let ins: insufficient =>
		return ins;
	};
	v.zoff = void;

	let dates: []date = [];

	// determine .loc
	if (v.vloc is chrono::locality) {
		v.loc = v.vloc as chrono::locality;
	} else if (v.locname is str) {
		for (let loc .. locs) {
			if (loc.name == v.locname as str) {
				v.loc = loc;
				v.vloc = loc;
				break;
			};
		};
	} else {
		return insufficient::LOCALITY;
	};

	// try matching zone abbreviation
	if (v.zabbr is str) {
		for (let zone .. v.loc.zones) {
			if (v.zabbr as str == zone.abbr) {
				v.zoff = zone.zoff;
				match (realize_validzoff(v, locs...)) {
				case let d: date =>
					match (sort::search(
						dates, size(date), &d, &cmpdates,
					)) {
					case size =>
						void;
					case void =>
						append(dates, d);
						sort::sort(dates, size(date), &cmpdates);
					};
				case invalid =>
					continue;
				case =>
					abort();
				};
			};
		};

		return invalid;
	};

	// try zone offsets from locality
	for (let zone .. v.loc.zones) {
		v.zoff = zone.zoff;
		match (realize_validzoff(v, locs...)) {
		case let d: date =>
			match (sort::search(dates, size(date), &d, &cmpdates)) {
			case size =>
				void;
			case void =>
				append(dates, d);
				sort::sort(dates, size(date), &cmpdates);
			};
		case invalid =>
			continue;
		case =>
			abort();
		};
	};

	return dates;
};

fn cmpdates(a: const *opaque, b: const *opaque) int = {
	let a = a: *date;
	let b = b: *date;
	return chrono::compare(a, b)!: int;
};

fn realize_gapbounds(v: virtual) (date, date) = {
	let loc = v.vloc as chrono::locality;

	let zlo: time::duration =  48 * time::HOUR;
	let zhi: time::duration = -48 * time::HOUR;
	for (let zone .. loc.zones) {
		if (zone.zoff > zhi) {
			zhi = zone.zoff;
		};
		if (zone.zoff < zlo) {
			zlo = zone.zoff;
		};
	};

	v.zoff = zhi;
	let earliest = realize_datetimezoff(v)!;
	let earliest = *(&earliest: *time::instant);

	v.zoff = zlo;
	let latest = realize_datetimezoff(v)!;
	let latest = *(&latest: *time::instant);

	let t = time::instant{ ... };
	for (let tr .. loc.transitions) {
		let is_within_bounds = (
			time::compare(earliest, tr.when) < 0
			&& time::compare(latest, tr.when) > 0
		);

		if (is_within_bounds) {
			t = tr.when;
			break;
		};
	};

	let gapstart = from_instant(loc, time::add(t, -time::NANOSECOND));
	let gapend   = from_instant(loc, t);

	// TODO: check if original v falls within gapstart & gapend?

	return (gapstart, gapend);
};
