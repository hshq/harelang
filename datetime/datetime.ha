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

// Creates a new datetime
//
// 	// 2038 January 19th 03:14:07.618 +0000
// 	datetime::new(2038, 01, 19, 03, 14, 07, 618, 0, chrono::local)
//
export fn new(
	year: int,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,
	zoffset: time::duration,
	loc: (*chrono::timezone | void),
) (datetime | errors::invalid) = {
	const dt = datetime {
		date        = calc_epochal_from_ymd(year, month, day)?,
		time        = calc_time_from_hmsn(hour, min, sec, nsec)?,
		loc         = if (loc is void) chrono::local else loc: *chrono::timezone,

		era         = void,
		year        = year,
		month       = month,
		day         = day,
		isoweekyear = void,
		isoweek     = void,
		week        = void,
		weekday     = void,
		yearday     = void,

		hour        = hour,
		min         = min,
		sec         = sec,
		nsec        = nsec,
	};
	return dt;
};

// Returns the current datetime
export fn now() datetime = {
	const i = time::now(time::clock::REALTIME);
	const unix = time::unix(i);
	const date = (unix / 86400);
	const dt = datetime {
		date        = date,
		time        = ((i.sec / 86400) * time::NANOSECOND + i.nsec),
		loc         = chrono::local,

		era         = void,
		year        = void,
		month       = void,
		day         = void,
		isoweekyear = void,
		isoweek     = void,
		week        = void,
		weekday     = void,
		yearday     = void,

		hour = (i.sec / 3600): int % 24,
		min  = (i.sec / 60): int % 60,
		sec  = i.sec: int % 60,
		nsec = i.nsec: int,
	};
	return dt;
};

// Creates a copy of a datetime
export fn clone(dt: datetime) datetime = {
	return datetime {
		date        = dt.date,
		time        = dt.time,
		loc         = dt.loc,

		era         = dt.era,
		year        = dt.year,
		month       = dt.month,
		day         = dt.day,
		isoweekyear = dt.isoweekyear,
		isoweek     = dt.isoweek,
		week        = dt.week,
		weekday     = dt.weekday,
		yearday     = dt.yearday,

		hour        = dt.hour,
		min         = dt.min,
		sec         = dt.sec,
		nsec        = dt.nsec,
	};
};

// Converts a [[datetime]] to a [[chrono::moment]]
export fn to_moment(dt: datetime) chrono::moment = {
	return chrono::moment {
		date = dt.date,
		time = dt.time,
		loc = dt.loc,
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
