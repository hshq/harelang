use time;
use chrono;
use errors;

// Represents a ISO datetime
//
// Notes:
// Java has good separation of types: A LocalDatetime, ZonedDatetime,
// OffsetDatetime. Python instead reasons about datetimes as being
// timezone-aware/naive. Here's I try to leaverage Hare's type system to combine
// the two.
//
// Putting the date and time related fields into separate typed structs maybe
// isn't a good idea (see `type localdate` below), but I still put it here
// because localtime is often used on it's own, and it makes some sense to have
// a datetime be composed of a date and time.
export type datetime = struct {
	date: localdate,
	time: localtime,
	loc: locality,
};

export type locality = chrono::locality;

// Creates a new moment
//
//	// 1995 July 18th 09:16:00.000
// 	isocal::new_moment(1995, 07, 18, 9, 16, 0, 0, isocal::local)
//
// For alternative forms, assemble a datetime manually using the desired types.
export fn new_moment(
	year: int,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,
	loc: locality,
) chrono::moment = {
	const dt = datetime {
		date = localdate {
			year = year,
			month = month,
			day = day,
		},
		time = localtime {
			hour = hour,
			min = min,
			sec = sec,
			nsec = nsec,
		},
		loc = loc,
	};
	const m = conv_datetime_moment(dt);
	return m;
};

// Creates a new datetime
//
//	// 1995 July 18th 09:16:00.000
// 	isocal::new(1995, 07, 18, 9, 16, 0, 0, isocal::local)
//
// For alternative forms, assemble a datetime manually using the desired types.
export fn new_datetime(
	year: int,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,
	loc: locality,
) (datetime | errors::invalid) = {
	const dt = datetime {
		date = localdate {
			year = year,
			month = month,
			day = day,
		},
		time = localtime {
			hour = hour,
			min = min,
			sec = sec,
			nsec = nsec,
		},
		loc = loc,
	};
	if (!validate(dt)) {
		return errors::invalid;
	};
	return dt;
};

// Returns the current moment
export fn now_moment() chrono::moment = {
	const i = time::now(time::clock::REALTIME);
	const u = time::unix(i);
	const d = (u / 86400);
	const t = (
		(i.sec * time::SECOND) + (i.nsec * time::NANOSECOND)
	) % (24 * time::HOUR);
	const m = chrono::moment {
		date = d,
		time = t,
		loc = chrono::local,
	};
	return m;
};

// Returns the current datetime
export fn now_datetime() datetime = {
	const i = time::now(time::clock::REALTIME);
	const u = time::unix(i);
	const d = (u / 86400);
	const ld = conv_epochal_localdate(d);
	const dt = datetime {
		date = ld,
		time = localtime {
			hour = (i.sec / 3600): int % 24,
			min  = (i.sec / 60): int % 60,
			sec  = i.sec: int % 60,
			nsec = i.nsec: int,
		},

		// TODO: What to do here? How to get the timezone from
		// /etc/localtime or $TZ? How to determine the system's
		// timescale?  Assuming UTC may be sufficient.
		loc = chrono::local,
	};
	return dt;
};

export fn validate(dt: datetime) bool = {
	// TODO
	return true;
};
