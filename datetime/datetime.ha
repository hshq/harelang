// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use errors;
use time;
use time::chrono;

// Invalid [[datetime]].
export type invalid = !chrono::invalid;

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
	min:         (void | int),
	sec:         (void | int),
	nsec:        (void | int),
};

fn init() datetime = datetime {
	date        = 0,
	time        = 0,
	loc         = chrono::LOCAL,
	zone        = chrono::zone { ... },

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
	min         = void,
	sec         = void,
	nsec        = void,
};

// Creates a new datetime. When loc=void, defaults to chrono::local.
//
// 	// 0000 Jan  1st 00:00:00.000000000 +0000 UTC
// 	datetime::new(time::chrono::UTC, 0);
//
// 	// 2038 Jan 19th 03:14:07.000000618 +0000 UTC
// 	datetime::new(time::chrono::UTC, 0, 2038, 1, 19, 3, 14, 7, 618);
//
// 	// 2038 Jan 19th 02:00:00.000000000 +0100 Europe/Amsterdam
// 	datetime::new(&time::chrono::tz("Europe/Amsterdam"), 1 * time::HOUR,
// 		2038, 1, 19, 2);
//
// 'offs' is the zone offset from the normal timezone (in most cases, UTC). For
// example, the "Asia/Tokyo" timezone has a single zoffset of +9 hours, but the
// "Australia/Sydney" timezone has zoffsets +10 hours and +11 hours, as they
// observe Daylight Saving Time.
//
// If specified (non-void), 'offs' must match one of the timezone's observed
// zoffsets, or will fail. See [[time::chrono::fixedzone]] for custom timezones.
//
// You may omit the zoffset. If the givem timezone has a single zone, [[new]]
// will use that zone's zoffset. Otherwise [[new]] will try to infer the zoffset
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
	offs: (time::duration | void),
	fields: int...
) (datetime | invalid) = {
	// TODO:
	// - revise examples
	// - Implement as described.
	// - fix calls with `years <= -4715`.
	//   https://todo.sr.ht/~sircmpwn/hare/565
	let defaults: [_]int = [
		0, 1, 1,    // year month day
		0, 0, 0, 0, // hour min sec nsec
	];

	if (len(fields) > len(defaults)) {
		// cannot specify more than 7 fields
		return invalid;
	};

	for (let i = 0z; i < len(fields); i += 1) {
		defaults[i] = fields[i];
	};

	const year  = defaults[0];
	const month = defaults[1];
	const day   = defaults[2];
	const hour  = defaults[3];
	const min   = defaults[4];
	const sec   = defaults[5];
	const nsec  = defaults[6];

	let m = chrono::moment {
		date = calc_date_from_ymd(year, month, day)?,
		time = calc_time_from_hmsn(hour, min, sec, nsec)?,
		loc = loc,
		zone = chrono::zone { ... },
	};

	// TODO: Set the correct values according to the given zo and
	// locality/timezone.
	//
	// figuring out what zone this moment observes
	if (offs is time::duration) {
		// Transform inversely to the moment that would transform back
		// to the current moment, then perform a zone lookup.
		m = chrono::transform(m, -(offs as time::duration));
		chrono::lookupzone(&m);
	} else {
		// Just perform a zone lookup, then try that zone and the
		// zones that are observed before and after. This requires
		// knowlegde of the transition index.
		//const z0 = chrono::lookupzone(*m);
		//m = chrono::transform(m, -z0.zoffset);
		abort("TODO"); // TODO
	};

	const dt = from_moment(m);
	if (
		year == _year(&dt)
		&& month == _month(&dt)
		&& day == _day(&dt)
		&& hour == _hour(&dt)
		&& min == _min(&dt)
		&& sec == _sec(&dt)
		&& nsec == _nsec(&dt)
	) {
		void;
	} else {
		return invalid;
	};
	return dt;
};

// Returns a [[datetime]] of the current system time,
// using [[time::clock::REALTIME]] and [[time::chrono::LOCAL]].
export fn now() datetime = {
	// TODO: Consider adding function parameters.
	// Should [[now]] specify appropriate params like a time::clock and
	// chrono::timezone? Perhaps a separate function, [[from_clock]].
	//
	// https://todo.sr.ht/~sircmpwn/hare/645
	const i = time::now(time::clock::REALTIME);
	const m = chrono::from_instant(i, chrono::LOCAL);
	return from_moment(m);
};

// Creates a [[datetime]] from a [[time::chrono::moment]].
export fn from_moment(m: chrono::moment) datetime = {
	const dt = init();
	dt.date = m.date;
	dt.time = m.time;
	dt.loc = m.loc;
	dt.zone = m.zone;
	return dt;
};

// Creates a [[datetime]] from a [[time::instant]]
// in a [[time::chrono::locality]].
export fn from_instant(i: time::instant, loc: chrono::locality) datetime = {
	return from_moment(chrono::from_instant(i, loc));
};

// Creates a [[time::instant]] from a [[datetime]].
export fn to_instant(dt: datetime) time::instant = {
	return chrono::to_instant(to_moment(dt));
};

// Creates a [[datetime]] from a string, parsed according to a layout,
// using [[strategy::ALL]], or otherwise fails.
export fn from_str(layout: str, s: str) (datetime | insufficient | invalid) = {
	// XXX: Should we allow the user to specify [[strategy]] for security?
	const b = newbuilder();
	parse(&b, layout, s)?;
	return finish(&b)?;
};

// Creates a [[time::chrono::moment]] from a [[datetime]].
export fn to_moment(dt: datetime) chrono::moment = {
	return chrono::moment {
		date = dt.date,
		time = dt.time,
		loc = dt.loc,
		zone = dt.zone,
	};
};

// A [[builder]] has insufficient information and cannot create a valid datetime.
export type insufficient = !void;

// A pseudo-datetime; a [[datetime]] which may hold invalid values, and does not
// guarantee internal validity or consistency.
//
// This can be used to construct new [[datetime]]s. Start with [[newbuilder]],
// then collect enough datetime information incrementally by direct field
// assignments and/or one or more calls to [[parse]]. Finish with [[finish]].
//
// 	let builder = datetime::newbuilder();
// 	datetime::parse(&builder, "Year: %Y", "Year: 2038");
// 	datetime::parse(&builder, "Month: %m", "Month: 01");
// 	builder.day = 19;
// 	let dt = datetime::finish(&builder, datetime::strategy::YMD);
//
export type builder = datetime;

// Creates a new [[builder]].
export fn newbuilder() builder = init(): builder;

// Returns a [[datetime]] from a [[builder]]. The provided [[strategy]]s will be
// tried in order until a valid datetime is produced, or otherwise fail. The
// default strategy is [[strategy::ALL]].
export fn finish(f: *builder, m: strategy...) (datetime | insufficient | invalid) = {
	if (len(m) == 0) {
		m = [strategy::ALL];
	};

	for (let i = 0z; i < len(m); i += 1) {
		const M = m[i];
		if (
			M & strategy::YMD != 0 &&
			f.year is int &&
			f.month is int &&
			f.day is int
		) {
			f.date = calc_date_from_ymd(
				f.year as int,
				f.month as int,
				f.day as int,
			)?;
			return *f: datetime;
		};

		if (
			M & strategy::YD != 0 &&
			f.year is int &&
			f.yearday is int
		) {
			f.date = calc_date_from_yd(
				f.year as int,
				f.yearday as int,
			)?;
			return *f: datetime;
		};

		if (
			M & strategy::YWD != 0 &&
			f.year is int &&
			f.week is int &&
			f.weekday is int
		) {
			f.date = calc_date_from_ywd(
				f.year as int,
				f.week as int,
				f.weekday as int,
			)?;
			return *f: datetime;
		};

		// TODO: calendar.ha: calc_date_from_isoywd()
	};

	return insufficient;
};

// Specifies which [[builder]] fields and what strategy to use to calculate the
// date, and thus a valid [[datetime]].
export type strategy = enum uint {
	// year, month, day
	YMD    = 1 << 0,
	// year, yearday
	YD     = 1 << 1,
	// year, week, weekday
	YWD    = 1 << 2,
	// isoyear, isoweek, weekday
	ISOYWD = 1 << 4,

	// all strategies, in order as presented here
	ALL    = YMD | YD | YWD | ISOYWD,
};
