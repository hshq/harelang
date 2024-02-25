// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;
use time::chrono;

// Invalid [[date]].
export type invalid = !chrono::invalid;

// A date/time object; a [[time::chrono::moment]] wrapper optimized for the
// Gregorian chronology, and by extension a [[time::instant]] wrapper.
//
// This object should be treated as private and immutable. Directly mutating its
// fields causes undefined behaviour when used with module functions. Likewise,
// interrogating the fields' type and value (e.g. using match statements) is
// also improper.
//
// A date observes various chronological values, cached in its fields. To
// evaluate and obtain these values, use the various observer functions
// ([[year]], [[hour]], etc.). These values are derived from the embedded moment
// information, and thus are guaranteed to be valid.
//
// See [[virtual]] for an public, mutable, intermediary representation of a
// date, which waives guarantees of validity.
export type date = struct {
	chrono::moment,

	era:         (void | int),
	year:        (void | int),
	month:       (void | int),
	day:         (void | int),
	yearday:     (void | int),
	isoweekyear: (void | int),
	isoweek:     (void | int),
	week:        (void | int),
	sundayweek:  (void | int),
	weekday:     (void | int),

	hour:        (void | int),
	minute:      (void | int),
	second:      (void | int),
	nanosecond:  (void | int),
};

fn init() date = date {
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
};

// Evaluates and populates all of a [[date]]'s fields.
fn all(d: *date) *date = {
	_era(d);
	_year(d);
	_month(d);
	_day(d);
	_yearday(d);
	_isoweekyear(d);
	_isoweek(d);
	_week(d);
	_sundayweek(d);
	_weekday(d);

	_hour(d);
	_minute(d);
	_second(d);
	_nanosecond(d);

	return d;
};

// Creates a new [[date]]. Upto seven field arguments can be given: year, month,
// day, hour, minute, second, nanosecond. 8 or more causes an abort. If omitted,
// the month and day default to 1, and the rest default to 0.
//
// Accepts a [[time::chrono::locality]], and a 'zoff' zone offset parameter
// which is used to discern the desired observed [[time::chrono::zone]] in the
// given locality. See [[time::chrono::fixedzone]] for custom timezones.
//
// An invalid zoff or field argument combination returns [[invalid]].
//
// Example:
//
// 	// 0000-01-01 00:00:00.000000000 +0000 UTC UTC
// 	date::new(time::chrono::UTC, 0);
//
// 	// 2019-12-27 20:07:08.000031415 +0000 UTC UTC
// 	date::new(time::chrono::UTC, 0,
// 		2019, 12, 27,  20,  7,  8, 31415);
//
// 	// 2019-12-27 21:00:00.000000000 +0100 CET Europe/Amsterdam
// 	date::new(time::chrono::tz("Europe/Amsterdam")!, 1 * time::HOUR,
// 		2019, 12, 27,  21);
//
// 	// 2019-12-27 10:00:00.000000000 -1000 HST Pacific/Honolulu
// 	date::new(time::chrono::tz("Pacific/Honolulu")!, -10 * time::HOUR,
// 		2019, 12, 27,  10);
//
// 	// Invalid month, day, hour, and minute
// 	date::new(time::chrono::UTC, 0,
// 		2019,  0,  0,  99, -30);
//
// 	// Invalid zoff
// 	date::new(time::chrono::UTC,       -7 * time::HOUR,  2019);
// 	date::new(time::chrono::tz("Europe/Amsterdam")!, 0,  2019);
//
// Example: Two dates, 30 physical minutes before and after a DST timezone
// transition, observing the same date/time, but different zone offsets:
//
// 	// 2019-04-07 02:30:00.000000000 +1100 AUDT Australia/Sydney
// 	date::new(time::chrono::tz("Australia/Sydney")!, 11 * time::HOUR,
// 		2019,  4,  7,   2, 30);
//
// 	// 2019-04-07 02:30:00.000000000 +1000 AUST Australia/Sydney
// 	date::new(time::chrono::tz("Australia/Sydney")!, 10 * time::HOUR,
// 		2019,  4,  7,   2, 30);
//
export fn new(
	loc: chrono::locality,
	zoff: time::duration,
	fields: int...
) (date | invalid) = {
	let _fields: [_]int = [
		0, 1, 1,    // year month day
		0, 0, 0, 0, // hour min sec nsec
	];

	assert(len(fields) <= len(_fields),
		"time::date::new(): Too many field arguments");
	_fields[..len(fields)] = fields;

	let v = newvirtual();

	v.vloc       = loc;
	v.zoff       = zoff;
	v.year       = _fields[0];
	v.month      = _fields[1];
	v.day        = _fields[2];
	v.hour       = _fields[3];
	v.minute     = _fields[4];
	v.second     = _fields[5];
	v.nanosecond = _fields[6];

	let d = (realize(v, loc) as (date | invalid))?;

	// check if input values are actually observed
	if (
		zoff != chrono::ozone(&d).zoff
		|| _fields[0] != _year(&d)
		|| _fields[1] != _month(&d)
		|| _fields[2] != _day(&d)
		|| _fields[3] != _hour(&d)
		|| _fields[4] != _minute(&d)
		|| _fields[5] != _second(&d)
		|| _fields[6] != _nanosecond(&d)
	) {
		return invalid;
	};

	return d;
};

// Returns a [[date]] of the current system time using
// [[time::clock::REALTIME]], in the [[time::chrono::LOCAL]] locality.
export fn now() date = {
	return from_instant(chrono::LOCAL, time::now(time::clock::REALTIME));
};

// Returns a [[date]] of the current system time using
// [[time::clock::REALTIME]], in the [[time::chrono::UTC]] locality.
export fn nowutc() date = {
	return from_instant(chrono::UTC, time::now(time::clock::REALTIME));
};

// Creates a [[date]] from a [[time::chrono::moment]].
export fn from_moment(m: chrono::moment) date = {
	const d = init();
	d.loc = m.loc;
	d.sec = m.sec;
	d.nsec = m.nsec;
	d.daydate = m.daydate;
	d.daytime = m.daytime;
	d.zone = m.zone;
	return d;
};

// Creates a [[date]] from a [[time::instant]] in a [[time::chrono::locality]].
export fn from_instant(loc: chrono::locality, i: time::instant) date = {
	return from_moment(chrono::new(loc, i));
};

// Creates a [[date]] from a string, parsed according to a layout format.
// See [[parse]] and [[format]]. At least a complete calendar date has to be
// provided. The if hour, minute, second, nanosecond, or zone offset are not
// provided, they default to 0.
//
// 	let new = date::from_str(
// 		date::STAMPLOC,
// 		"2019-12-27 22:07:08.000000000 +0100 CET Europe/Amsterdam",
// 		locs...
// 	)!;
//
// The date's [[time::chrono::locality]] will be selected from the provided
// locality arguments. The 'name' field of these localities will be matched
// against the parsed result for the %L specifier. If %L is not specified, or if
// no locality is provided, [[time::chrono::UTC]] is used.
export fn from_str(
	layout: str,
	s: str,
	locs: chrono::locality...
) (date | parsefail | insufficient | invalid) = {
	const v = newvirtual();
	v.zoff = 0;
	v.hour = 0;
	v.minute = 0;
	v.second = 0;
	v.nanosecond = 0;
	parse(&v, layout, s)?;
	return realize(v, locs...)?;
};

@test fn from_str() void = {
	let testcases: [_](str, str, []chrono::locality, (date | error)) = [
		(STAMPLOC, "2001-02-03 15:16:17.123456789 +0000 UTC UTC", [],
			new(chrono::UTC, 0, 2001, 2, 3, 15, 16, 17, 123456789)!),
		(STAMP, "2001-02-03 15:16:17", [],
			new(chrono::UTC, 0, 2001, 2, 3, 15, 16, 17)!),
		(RFC3339, "2001-02-03T15:16:17+0000", [],
			new(chrono::UTC, 0, 2001, 2, 3, 15, 16, 17)!),
		("%F", "2009-06-30", [],
			new(chrono::UTC, 0, 2009, 6, 30)!),
		("%F %L", "2009-06-30 GPS", [chrono::TAI, chrono::GPS],
			new(chrono::GPS, 0, 2009, 6, 30)!),
		("%F %T", "2009-06-30 01:02:03", [],
			new(chrono::UTC, 0, 2009, 6, 30, 1, 2, 3)!),
		("%FT%T%Z", "2009-06-30T18:30:00Z", [],
			new(chrono::UTC, 0, 2009, 6, 30, 18, 30)!),
		("%FT%T.%N%Z", "2009-06-30T18:30:00.987654321Z", [],
			new(chrono::UTC, 0, 2009, 6, 30, 18, 30, 0, 987654321)!),
		// TODO: for the tests overhaul, when internal test timezones
		// are available, check for %L
		//("%FT%T%z %L", "2009-06-30T18:30:00+0200 Europe/Amsterdam", [amst],
		//	new(amst, 2 * time::HOUR, 2009, 6, 30, 18, 30)!),

		("%Y", "a", [], (0z, 'a'): parsefail),
		("%X", "2008", [], (0z, '2'): parsefail),
	];

	let buf: [64]u8 = [0...];
	for (let i = 0z; i < len(testcases); i += 1) {
		const t = testcases[i];
		const expect = t.3;
		const actual = from_str(t.0, t.1, t.2...);

		match (expect) {
		case let e: date =>
			assert(actual is date, "wanted 'date', got 'error'");
			assert(chrono::eq(&(actual as date), &e)!,
				"incorrect 'date' value");
		case let e: parsefail =>
			assert(actual is parsefail,
				"wanted 'parsefail', got other");
		case insufficient =>
			assert(actual is insufficient,
				"wanted 'insufficient', got other");
		case invalid =>
			assert(actual is invalid,
				"wanted 'invalid', got other");
		};
	};
};
