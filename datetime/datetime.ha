use errors;
use time;
use time::chrono;

// Represents a datetime; a single, reasonably unique moment in time, specified
// by a calendar date and a wallclock time, contextualised within a locality.
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
	zone        = chrono::zone{ ... },
	loc         = &chrono::local,

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
//	// 2038 January 19th 03:14:07.000
// 	datetime::new(2038, 01, 19, 03, 14, 07, 0, 0, &chrono::local)
//
export fn new(
	year: int,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,
	zoffset: chrono::zoffset,
	loc: (*chrono::timezone | void),
) (datetime | errors::invalid) = {
	const dt = datetime {
		date        = calc_epochal_from_ymd(year, month, day)?,
		time        = calc_time_from_hmsn(hour, min, sec, nsec)?,
		zone        = chrono::zone{ zoffset = zoffset, ... },
		loc         = if (loc is void) &chrono::local else loc: *chrono::timezone,

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

		// TODO: What to do here? How to get the timezone from
		// /etc/localtime or $TZ? How to determine the system's
		// timescale?  Assuming UTC may be sufficient.
		zone        = chrono::zone{ ... },
		loc         = &chrono::local,

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

// Validates a datetime's internal date & time values
export fn validate(dt: datetime) bool = {
	// TODO
	return true;
};


// A builder has insufficient information and cannot create a valid datetime.
export type insufficient = !void;

// Constructs a new datetime, from assigning values to its fields, or multiple
// calls to [[parse]]. A valid datetime is returned via [[build]].
export type builder = datetime;

// Creates a new [[builder]]
export fn newbuilder() builder = init(): builder;

// Returns a valid datetime from a builder. The following approaches will be
// tried in order until a valid datetime is produced, or fail otherwise:
// - year, month, day
// - year, yearday
// - year, week, weekday
// - isoyear, isoweek, weekday
//
// TODO: Should we use an enum to select the approach?
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

export type method = enum uint {
	YMD    = 1 << 0,
	YD     = 1 << 1,
	YWD    = 1 << 2,
	ISOYWD = 1 << 4,
	ALL    = YMD | YD | YWD | ISOYWD,
};
