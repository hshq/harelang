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
