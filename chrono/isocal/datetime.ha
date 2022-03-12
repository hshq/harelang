use time;

// Creates a new datetime, using a [[calendardate]].
//
//	// 1995 July 18th 09:16:00.000
// 	datetime::new(1995, 07, 18, 9, 16, 0, 0, datetime::local)
// 	chrono::iso::new(1995, 07, 18, 9, 16, 0, 0, chrono::iso::local)
//
// For alternative forms, assemble a datetime manually using the desired types.
export fn new(
	year: i64,
	month: u8,
	day: u8,
	hour: u8,
	min: u8,
	sec: u8,
	nsec: u64,
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
			day   = (i.sec / 86400): u8,
		},
		time = localtime {
			hour = (i.sec / 3600): u8 % 24,
			min  = (i.sec / 60): u8 % 60,
			sec  = i.sec: u8 % 60,
			nsec = i.nsec: u64,
		},

		// TODO: What to do here? How to get the timezone from
		// /etc/localtime? How to determine the system's timescale?
		// Assuming UTC may be sufficient.
		loc = local,
	};
	return dt;
};

// Normalizes all fields a datetime
export fn normalize(dt: datetime) datetime = {
	validate(dt)!;
	// TODO
	return dt;
};

// Validates a datetime
export fn validate(dt: datetime) (datetime | error) = {
	// TODO
	return dt;
};

export type error = !void;
