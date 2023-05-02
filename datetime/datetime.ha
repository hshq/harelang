// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use errors;
use time;
use time::chrono;

// Invalid [[datetime]].
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
// A datetime observes various chronological values, cached in its fields. To
// evaluate and obtain these values, use the various "observe" functions
// ([[year]], [[day]], etc.). These values are derived from the embedded moment
// information, and thus are guaranteed to be valid.
//
// See [[virtual]] for an public, mutable, intermediary representation of a
// datetime, which waives guarantees of validity.
export type datetime = struct {
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

fn init() datetime = datetime {
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

// Evaluates and populates all of a [[datetime]]'s fields.
fn all(dt: *datetime) *datetime = {
	_era(dt);
	_year(dt);
	_month(dt);
	_day(dt);
	_yearday(dt);
	_isoweekyear(dt);
	_isoweek(dt);
	_week(dt);
	_sundayweek(dt);
	_weekday(dt);

	_hour(dt);
	_minute(dt);
	_second(dt);
	_nanosecond(dt);

	return dt;
};

// Creates a new datetime. A maximum of 7 optional field arguments can be given:
// year, month, day-of-month, hour, minute, second, nanosecond. 8 or more causes
// an abort.
//
// 	// 0000-01-01 00:00:00.000000000 +0000 UTC UTC
// 	datetime::new(time::chrono::UTC, 0);
//
// 	// 2019-12-27 20:07:08.000031415 +0000 UTC UTC
// 	datetime::new(time::chrono::UTC, 0,  2019, 12, 27,  20, 07, 08, 31415);
//
// 	// 2019-12-27 21:00:00.000000000 +0100 CET Europe/Amsterdam
// 	datetime::new(time::chrono::tz("Europe/Amsterdam")!, 1 * time::HOUR,
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
// where certain datetimes are ambiguous or nonexistent. For example:
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
) (datetime | invalid) = {
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
			"datetime::new(): Too many field arguments");
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
		abort("TODO: datetime::new(zo=void)");
	};

	const dt = from_moment(m);

	const zo = match (zo) {
	case void =>
		yield chrono::mzone(&m).zoff;
	case let d: time::duration =>
		yield d;
	};

	// check if input values are actually observed
	if (
		zo       != chrono::mzone(&dt).zoff
		|| year  != _year(&dt)
		|| month != _month(&dt)
		|| day   != _day(&dt)
		|| hour  != _hour(&dt)
		|| min   != _minute(&dt)
		|| sec   != _second(&dt)
		|| nsec  != _nanosecond(&dt)
	) {
		return invalid;
	};

	return dt;
};

// Returns a [[datetime]] of the current system time using
// [[time::clock::REALTIME]], in the [[time::chrono::LOCAL]] locality.
export fn now() datetime = {
	return from_instant(chrono::LOCAL, time::now(time::clock::REALTIME));
};

// Returns a [[datetime]] of the current system time using
// [[time::clock::REALTIME]], in the [[time::chrono::UTC]] locality.
export fn nowutc() datetime = {
	return from_instant(chrono::UTC, time::now(time::clock::REALTIME));
};

// Creates a [[datetime]] from a [[time::chrono::moment]].
export fn from_moment(m: chrono::moment) datetime = {
	const dt = init();
	dt.loc = m.loc;
	dt.sec = m.sec;
	dt.nsec = m.nsec;
	dt.date = m.date;
	dt.time = m.time;
	dt.zone = m.zone;
	return dt;
};

// Creates a [[datetime]] from a [[time::instant]]
// in a [[time::chrono::locality]].
export fn from_instant(loc: chrono::locality, i: time::instant) datetime = {
	return from_moment(chrono::new(loc, i));
};

// Creates a [[datetime]] from a string, parsed according to a layout format.
// See [[parse]] and [[format]].
//
// 	let new = datetime::from_str(
// 		datetime::STAMP_NOZL,
// 		"2019-12-27 22:07:08.000000000 +0100 CET Europe/Amsterdam",
// 		locs...
// 	)!;
//
// The datetime's [[time::chrono::locality]] will be selected from the provided
// locality arguments. The 'name' field of these localities will be matched
// against the parsed result for the %L specifier. If %L is not specified, or if
// no locality is provided, [[time::chrono::UTC]] is used.
export fn from_str(
	layout: str,
	s: str,
	locs: time::chrono::locality...
) (datetime | parsefail | insufficient | invalid) = {
	const v = newvirtual();
	parse(&v, layout, s)?;
	return realize(v, locs...)?;
};
