use errors;
use time;
use time::chrono;

// A valid date & time, localized in a timezone; an extended chrono::moment,
// optimized for use with the Gregorian chronology.
//
// Fields of type (void | int) should be treated as private. Their values are
// produced and cached via their respectively named functions ([[year]], etc).
// Direct field assignements will result in errors; see [[builder]].
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
	loc         = chrono::local,
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
// 	// 2038 January 19th 03:14:07.000000618 +0000 Local
// 	datetime::new(2038, 01, 19, 03, 14, 07, 618, void, void);
//
// 	// 2038 January 19th 03:14:07.000000618 +0100 Europe/Amsterdam
// 	datetime::new(2038, 01, 19, 03, 14, 07, 618,
// 		1 * time::HOUR, &olson::tz("Europe/Amsterdam"));
//
// TODO: revise examples
//
// zoffset is the zone offset from the normal timezone (in most cases, UTC0).
// For example, the "Asia/Tokyo" timezone has a single zoffset of +9 hours,
// but the "Australia/Sydney" timezone has zoffsets +10 hours and +11 hours, as
// they observe Daylight Saving Time.
//
// if specified (non-void), zoffset must match one of the timezone's observed
// zoffsets, or will fail. See [[chrono::fixedzone]] for custom timezones.
//
// You may omit the zoffset. If the givem timezone has a single zone, [[new]]
// will use that zone's zoffset. Otherwise [[new]] will try to infer the zoffset
// from the multiple zones. This will fail during certain timezone transitions,
// where certain datetimes are [[ambiguous]] or [[nonexistant]]. For example:
//
// - In the Europe/Amsterdam timezone, at 1995 March 26th,
//   the local time 02:30 was never observed,
//   as the clock jumped forward 1 hour from 01:00 CET.
//
// - In the Europe/Amsterdam timezone, at 1995 September 24th,
//   the local time 02:30 was observed twice (00:30 UTC & 01:30 UTC),
//   as the clock jumped back 1 hour from 02:00 CEST.
//
// TODO: implement as described.
export fn new(
	year: int,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,

	// normal offset (offset from normal timezone (UTC0, TAI0, etc.))
	//
	// TODO: type `(time::duration | first | last)`? Would automatically
	// pick the first/last occurence of an ambiguous datetime, as described
	// above.
	zoffset: (time::duration | void),

	// TODO: should this be `nullable *chrono::timezone`?
	// would interface better with other code, i presume.
	loc: (*chrono::timezone | void),
) (datetime | errors::invalid) = {
	// TODO: set the correct values according to the given zoffset and
	// locality/timezone.
	const m = chrono::new(
		calc_epochal_from_ymd(year, month, day)?,
		calc_time_from_hmsn(hour, min, sec, nsec)?,
		if (loc is void) chrono::local else loc: *chrono::timezone,
	);
	return from_moment(m);
};

// Returns a [[datetime]] of the immediate system time
export fn now() datetime = {
	// TODO: should the clock and timezone be choosable?
	const i = time::now(time::clock::REALTIME);
	const m = chrono::from_instant(i, chrono::local);
	return from_moment(m);
};

// Creates a copy of a [[datetime]]
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
// using [[method::ALL]], or fails otherwise.
//
// TODO: allow the user to specify methods for security?
export fn from_str(layout: str, s: str) (datetime | insufficient | errors::invalid) = {
	const b = newbuilder();
	parse(&b, layout, s)?;
	return build(&b)?;
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

// A builder has insufficient information and cannot create a valid datetime.
export type insufficient = !void;

// Constructs a new datetime. Start with [[newbuilder]]. Collect enough datetime
// information incrementally by direct field assignments or multiple calls to
// [[parse]]. Finish with [[build]].
//
// 	let builder = datetime::newbuilder();
// 	datetime::parse(&builder, "Year: %Y", "Year: 2038");
// 	datetime::parse(&builder, "Month: %m", "Month: 01");
// 	builder.day = 19;
// 	let dt = datetime::build(&builder, datetime::method::YMD);
//
export type builder = datetime;

// Creates a new [[builder]]
export fn newbuilder() builder = init(): builder;

// Returns a datetime from a builder. The provided methods will be tried in
// order until a valid datetime is produced, or fail otherwise. The default
// method is [[method::ALL]].
export fn build(f: *builder, m: method...) (datetime | insufficient | errors::invalid) = {
	if (len(m) == 0) {
		m = [method::ALL];
	};

	for (let i = 0z; i < len(m); i += 1) {
		const M = m[i];
		if (
			M & method::YMD != 0 &&
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
			M & method::YD != 0 &&
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
			M & method::YWD != 0 &&
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

// Specifies which [[builder]] fields (and what method) to use to calculate the
// epochal, and thus a valid datetime.
export type method = enum uint {
	// year, month, day
	YMD    = 1 << 0,
	// year, yearday
	YD     = 1 << 1,
	// year, week, weekday
	YWD    = 1 << 2,
	// isoyear, isoweek, weekday
	ISOYWD = 1 << 4,

	// all methods, in order as presented here
	ALL    = YMD | YD | YWD | ISOYWD,
};

@test fn clone() void = {
	let d0 = datetime::new(2038, 01, 19, 03, 14, 07, 0, 0, chrono::local)!;
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
