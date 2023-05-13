// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use errors;
use time;
use time::chrono;

// Invalid [[date]].
export type invalid = !chrono::invalid;

// A date/time object; a [[time::chrono::moment]] wrapper optimized for the
// Gregorian chronology
//
// It is by extension a [[time::instant]] wrapper, and carries information about
// its [[time::chrono::timescale]] and [[time::chrono::locality]].
//
// This object should be treated as private and immutable. Directly mutating its
// fields causes undefined behaviour when used with module functions. Likewise,
// interrogating the fields' type and value (e.g. using match statements) is
// also improper.
//
// A date observes various chronological values, cached in its fields. To
// evaluate and obtain these values, use the various "observe" functions
// ([[year]], [[day]], etc.). These values are derived from the embedded moment
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
	date        = void,
	time        = void,

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

// Creates a new [[date]]. A maximum of 7 optional field arguments can be given:
// year, month, day-of-month, hour, minute, second, nanosecond. 8 or more causes
// an abort.
//
// 	// 0000-01-01 00:00:00.000000000 +0000 UTC UTC
// 	date::new(time::chrono::UTC, 0);
//
// 	// 2019-12-27 20:07:08.000031415 +0000 UTC UTC
// 	date::new(time::chrono::UTC, 0,  2019, 12, 27,  20, 07, 08, 31415);
//
// 	// 2019-12-27 21:00:00.000000000 +0100 CET Europe/Amsterdam
// 	date::new(time::chrono::tz("Europe/Amsterdam")!, 1 * time::HOUR,
// 		2019, 12, 27,  21);
//
// 'zo' is the zone offset from the normal timezone (in most cases, UTC). For
// example, the "Asia/Tokyo" timezone has a single zoff of +9 hours, but the
// "Australia/Sydney" timezone has zoffs +10 hours and +11 hours, as they
// observe Daylight Saving Time.
//
// If specified (non-void), 'zo' must match one of the timezone's observed
// zoffs, or will fail. See [[time::chrono::fixedzone]] for custom timezones.
//
// You may omit the zoff. If the givem timezone has a single zone, [[new]]
// will use that zone's zoff. Otherwise [[new]] will try to infer the zoff
// from the multiple zones. This will fail during certain timezone transitions,
// where certain dates are ambiguous or nonexistent. For example:
//
// - In the Europe/Amsterdam timezone, at 1995 March 26th,
//   the local time 02:30 was never observed,
//   as the clock jumped forward 1 hour from 02:00 CET to 03:00 CEST.
//
// - In the Europe/Amsterdam timezone, at 1995 September 24th,
//   the local time 02:30 was observed twice (00:30 UTC & 01:30 UTC),
//   as the clock jumped back 1 hour from 03:00 CEST to 02:00 CET.
export fn new(
	loc: chrono::locality,
	zo: (time::duration | void),
	fields: int...
) (date | invalid) = {
	// TODO:
	// - revise examples
	// - Implement as described.
	// - fix calls with `years <= -4715`.
	//   https://todo.sr.ht/~sircmpwn/hare/565
	let _fields: [_]int = [
		0, 1, 1,    // year month day
		0, 0, 0, 0, // hour min sec nsec
	];

	assert(len(fields) <= len(_fields),
			"time::date::new(): Too many field arguments");
	_fields[..len(fields)] = fields;

	const year  = _fields[0];
	const month = _fields[1];
	const day   = _fields[2];
	const hour  = _fields[3];
	const min   = _fields[4];
	const sec   = _fields[5];
	const nsec  = _fields[6];

	const mdate = calc_date__ymd(year, month, day)?;
	const mtime = calc_time__hmsn(hour, min, sec, nsec)?;

	// create the moment
	const m = match (zo) {
	case let zo: time::duration =>
		yield chrono::from_datetime(loc, zo, mdate, mtime);
	case void =>
		// TODO: Deduce the zone offset
		//
		// perform a zone lookup, then try that zone and the zones that
		// are observed before and after. This requires knowlegde of the
		// transition index.
		abort("TODO: time::date::new(zo=void)");
	};

	const d = from_moment(m);

	const zo = match (zo) {
	case void =>
		yield chrono::mzone(&m).zoff;
	case let zo: time::duration =>
		yield zo;
	};

	// check if input values are actually observed
	if (
		zo       != chrono::mzone(&d).zoff
		|| year  != _year(&d)
		|| month != _month(&d)
		|| day   != _day(&d)
		|| hour  != _hour(&d)
		|| min   != _minute(&d)
		|| sec   != _second(&d)
		|| nsec  != _nanosecond(&d)
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
	d.date = m.date;
	d.time = m.time;
	d.zone = m.zone;
	return d;
};

// Creates a [[date]] from a [[time::instant]]
// in a [[time::chrono::locality]].
export fn from_instant(loc: chrono::locality, i: time::instant) date = {
	return from_moment(chrono::new(loc, i));
};

// Creates a [[date]] from a string, parsed according to a layout format.
// See [[parse]] and [[format]]. At least a complete calendar date has to be
// provided. The if hour, minute, second, nanosecond, or zone offset are not
// provided, they default to 0.
//
// 	let new = date::from_str(
// 		date::STAMP_NOZL,
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
	locs: time::chrono::locality...
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
	const amst = chrono::tz("Europe/Amsterdam")!;
	defer chrono::timezone_free(amst);

	let testcases: [_](str, str, []chrono::locality, (date | error)) = [
		(STAMP_NOZL, "2001-02-03 15:16:17.123456789 +0000 UTC UTC", [],
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
		("%FT%T%z %L", "2009-06-30T18:30:00+0200 Europe/Amsterdam", [amst],
			new(amst, 2 * time::HOUR, 2009, 6, 30, 18, 30)!),

		("%Y", "a", [], 'a': parsefail),
		("%X", "2008", [], '2': parsefail),
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
