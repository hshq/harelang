use time;

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

// Creates a new datetime
//
//	// 1995 July 18th 09:16:00.000
// 	isocal::new(1995, 07, 18, 9, 16, 0, 0, isocal::local)
//
// For alternative forms, assemble a datetime manually using the desired types.
export fn new(
	year: i64,
	month: int,
	day: int,
	hour: int,
	min: int,
	sec: int,
	nsec: int,
	loc: locality,
) datetime = datetime {
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

// Returns the current datetime
export fn now() datetime = {
	const i = time::now(time::clock::REALTIME);
	const u = time::unix(i);
	const dt = datetime {
		date = localdate {
			// TODO: figure out calendar arithmetics first
			year  = 1970,
			month = 1,
			day   = (i.sec / 86400): int,
		},
		time = localtime {
			hour = (i.sec / 3600): int % 24,
			min  = (i.sec / 60): int % 60,
			sec  = i.sec: int % 60,
			nsec = i.nsec: int,
		},

		// TODO: What to do here? How to get the timezone from
		// /etc/localtime or $TZ? How to determine the system's
		// timescale?  Assuming UTC may be sufficient.
		loc = local,
	};
	return dt;
};

export type error = !void;
