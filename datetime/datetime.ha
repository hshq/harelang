use errors;
use time;
use time::chrono;

// The given combination of date, time, and locality is invalid.
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
// 	datetime::new(time::chrono::UTC, 0, 2038, 01, 19, 03, 14, 07, 618);
//
// 	// 2038 Jan 19th 02:00:00.000000000 +0100 Europe/Amsterdam
// 	datetime::new(&time::tzdb::tz("Europe/Amsterdam"), 1 * time::HOUR,
// 		2038, 01, 19, 02);
//
// TODO: revise examples
//
// zo is the zone offset from the normal timezone (in most cases, UTC). For
// example, the "Asia/Tokyo" timezone has a single zoffset of +9 hours, but the
// "Australia/Sydney" timezone has zoffsets +10 hours and +11 hours, as they
// observe Daylight Saving Time.
//
// if specified (non-void), zo must match one of the timezone's observed
// zoffsets, or will fail. See [[chrono::fixedzone]] for custom timezones.
//
// You may omit the zoffset. If the givem timezone has a single zone, [[new]]
// will use that zone's zoffset. Otherwise [[new]] will try to infer the zoffset
// from the multiple zones. This will fail during certain timezone transitions,
// where certain datetimes are [[ambiguous]] or [[nonexistant]]. For example:
//
// - In the Europe/Amsterdam timezone, at 1995 March 26th,
//   the local time 02:30 was never observed,
//   as the clock jumped forward 1 hour from 02:00 CET to 03:00 CEST.
//
// - In the Europe/Amsterdam timezone, at 1995 September 24th,
//   the local time 02:30 was observed twice (00:30 UTC & 01:30 UTC),
//   as the clock jumped back 1 hour from 03:00 CEST to 02:00 CET.
//
// TODO: Implement as described.
//
// TODO: Allow and correct for overflowing units like Golang? Most likely not.
// Defeats the purpose of validation at creation. I see little benefit.
//
// TODO: fix calls with `years <= -4715`. https://todo.sr.ht/~sircmpwn/hare/565
//
export fn new(
	// TODO: should this be `nullable *chrono::timezone`?
	// would interface better with other code, i presume.
	loc: (*chrono::timezone | void),

	// normal offset (offset from normal timezone (UTC0, TAI0, etc.))
	//
	// TODO: type `(time::duration | first | last)`? or
	// TODO: type `(time::duration | enum { FIRST, LAST } )`?
	// Would automatically pick the first/last occurence of an ambiguous
	// datetime, as described above.
	zo: (time::duration | void),

	fields: int...

// TODO: improve variety of errors.
// `invaliddatetime = !void` ?
// `invaliddatetime = !datetime::mock` ?
) (datetime | invalid) = {
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
		date = calc_epochal_from_ymd(year, month, day)?,
		time = calc_time_from_hmsn(hour, min, sec, nsec)?,
		loc = if (loc is void) chrono::LOCAL else loc: *chrono::timezone,
		zone = chrono::zone { ... },
	};

	// TODO: Set the correct values according to the given zo and
	// locality/timezone.
	//
	// figuring out what zone this moment observes
	if (zo is time::duration) {
		// Transform inversely to the moment that would transform back
		// to the current moment, then perform a zone lookup.
		m = chrono::transform(m, -(zo as time::duration));
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

// Returns a [[datetime]] of the immediate system time
//
// TODO: specify appropriate params like a time::clock and chrono::timezone.
export fn now() datetime = {
	const i = time::now(time::clock::REALTIME);
	const m = chrono::from_instant(i, chrono::LOCAL);
	return from_moment(m);
};

// Creates a copy of a [[datetime]]
//
// TODO: remove, purge from other functions, seems useless.
export fn clone(dt: datetime) datetime = dt;

// Creates a [[datetime]] from a [[chrono::moment]]
export fn from_moment(m: chrono::moment) datetime = {
	const dt = init();
	dt.date = m.date;
	dt.time = m.time;
	dt.loc = m.loc;
	dt.zone = m.zone;
	return dt;
};

// Creates a [[datetime]] from a string, parsed according to a layout,
// using [[strategy::ALL]], or fails otherwise.
//
// TODO: allow the user to specify [[strategy]] for security?
export fn from_str(layout: str, s: str) (datetime | insufficient | invalid) = {
	const b = newmock();
	parse(&b, layout, s)?;
	return finish(&b)?;
};

// Creates a [[chrono::moment]] from a [[datetime]]
export fn to_moment(dt: datetime) chrono::moment = {
	return chrono::moment {
		date = dt.date,
		time = dt.time,
		loc = dt.loc,
		zone = dt.zone,
	};
};

// A [[mock]] has insufficient information and cannot create a valid datetime.
export type insufficient = !void;

// Constructs a new datetime. Start with [[newmock]]. Collect enough datetime
// information incrementally by direct field assignments or multiple calls to
// [[parse]]. Finish with [[finish]].
//
// 	let mock = datetime::newmock();
// 	datetime::parse(&mock, "Year: %Y", "Year: 2038");
// 	datetime::parse(&mock, "Month: %m", "Month: 01");
// 	mock.day = 19;
// 	let dt = datetime::finish(&mock, datetime::strategy::YMD);
//
export type mock = datetime;

// Creates a new [[mock]]
export fn newmock() mock = init(): mock;

// Returns a datetime from a mock. The provided [[strategy]]s will be tried in
// order until a valid datetime is produced, or fail otherwise. The default
// strategy is [[strategy::ALL]].
export fn finish(f: *mock, m: strategy...) (datetime | insufficient | invalid) = {
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
			f.date = calc_epochal_from_ymd(
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
			f.date = calc_epochal_from_yd(
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
			f.date = calc_epochal_from_ywd(
				f.year as int,
				f.week as int,
				f.weekday as int,
			)?;
			return *f: datetime;
		};

		// TODO: calendar.ha: calc_epochal_from_isoywd()
	};

	return insufficient;
};

// Specifies which [[mock]] fields (and what strategy) to use to calculate the
// epochal, and thus a valid datetime.
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

@test fn clone() void = {
	let d0 = datetime::new(chrono::UTC, 0, 2038, 01, 19, 03, 14, 07, 0)!;
	let d1 = clone(d0);
	assert(d0.year as int == d1.year as int &&
		d0.month as int == d1.month as int &&
		d0.day as int == d1.day as int &&
		d0.hour as int == d1.hour as int &&
		d0.min as int == d1.min as int &&
		d0.sec as int == d1.sec as int &&
		d0.nsec as int == d1.nsec as int,
		"cloned date not equal to original date");
};
