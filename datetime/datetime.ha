use errors;
use time;
use time::chrono;

// Represents a datetime; a single, reasonably unique moment in time, specified
// by a calendar date and a wallclock time, contextualised within a locality.
export type datetime = struct {
	date: localdate,
	time: localtime,
	loc: locality,
};

fn init_datetime() datetime = datetime {
	date = init_date(),
	time = init_time(),
	loc = chrono::local,
};

// Creates a new datetime
//
//	// 2038 January 19th 03:14:07.000
// 	datetime::new(2038, 01, 19, 03, 14, 07, 0, chrono::local)
//
export fn new(
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
			epochal = void,
			era = void,
			year = year,
			month = month,
			day = day,
			isoweekyear = void,
			isoweek = void,
			week = void,
			weekday = void,
			yearday = void,
		},
		time = localtime {
			lapsed = void,
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

// Returns the current datetime
export fn now() datetime = {
	const i = time::now(time::clock::REALTIME);
	const u = time::unix(i);
	const d = (u / 86400);
	const ld = init_date();
	ld.epochal = d: int;
	const dt = datetime {
		date = ld,
		time = localtime {
			lapsed = ((i.sec / 86400) * time::NANOSECOND + i.nsec): int,
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

// Validates a datetime's internal date & time values
export fn validate(dt: (datetime | localdate | localtime)) bool = {
	// TODO
	return true;
};

//	// Creates a new moment
//	//
//	//	// 1995 July 18th 09:16:00.000
//	// 	datetime::new_moment(1995, 07, 18, 9, 16, 0, 0, chrono::local)
//	//
//	// For alternative forms, assemble a datetime manually using the desired types.
//	export fn new_moment(
//		year: int,
//		month: int,
//		day: int,
//		hour: int,
//		min: int,
//		sec: int,
//		nsec: int,
//		loc: locality,
//	) (chrono::moment | errors::invalid) = {
//		const dt = new(year, month, day, hour, min, sec, nsec, loc)?;
//		const m = conv_datetime_moment(dt)?;
//		return m;
//	};

//	// Returns the current moment
//	export fn now_moment() chrono::moment = {
//		const i = time::now(time::clock::REALTIME);
//		const u = time::unix(i);
//		const d = (u / 86400);
//		const t = (
//			(i.sec * time::SECOND) + (i.nsec * time::NANOSECOND)
//		) % (24 * time::HOUR);
//		const m = chrono::moment {
//			date = d,
//			time = t,
//			loc = chrono::local,
//		};
//		return m;
//	};
