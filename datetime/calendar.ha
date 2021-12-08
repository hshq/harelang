use errors;
use time;
use time::chrono;

// TODO: reconcile what epochs to use for time::chrono and datetime::
//
// 1970-01-01 "Hare epoch"
// 0000-01-01 Gregorian epoch

// The Hare epoch of the Julian Day Number
export def EPOCH_JULIAN: i64 = -2440588;

// The Hare epoch of the Common Era
export def EPOCH_COMMONERA: i64 = -719164;


//
// date-like
//

// Evaluates a [[datetime]]'s number of days since the calendar epoch 0000-01-01
export fn epochal(dt: *datetime) int = {
	match (dt.date.epochal) {
	case void =>
		// How to resolve?
		// Use calc_epochal_from_*? How to avoid recursion?
		// When to rely on input validation?
		abort("TODO");
	case let e: int =>
		return e;
	};
};

// Evaluates a [[datetime]]'s era
export fn era(dt: *datetime) int = {
	match (dt.date.era) {
	case void =>
		if (dt.date.year is void) {
			dt.date.year = year(dt);
		};
		dt.date.era = calc_era(dt.date.year: int);
		return dt.date.era: int;
	case let a: int =>
		return a;
	};
};

// Evaluates a [[datetime]]'s year
export fn year(dt: *datetime) int = {
	match (dt.date.year) {
	case void =>
		if (dt.date.epochal is void) {
			epochal(dt);
		};
		const ymd = calc_ymd(dt.date.epochal: int);
		dt.date.year = ymd.0;
		dt.date.month = ymd.1;
		dt.date.day = ymd.2;
		return dt.date.year: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s month of the year
export fn month(dt: *datetime) int = {
	match (dt.date.month) {
	case void =>
		if (dt.date.epochal is void) {
			epochal(dt);
		};
		const ymd = calc_ymd(dt.date.epochal: int);
		dt.date.year = ymd.0;
		dt.date.month = ymd.1;
		dt.date.day = ymd.2;
		return dt.date.month: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s day of the month
export fn day(dt: *datetime) int = {
	match (dt.date.day) {
	case void =>
		if (dt.date.epochal is void) {
			epochal(dt);
		};
		const ymd = calc_ymd(dt.date.epochal: int);
		dt.date.year = ymd.0;
		dt.date.month = ymd.1;
		dt.date.day = ymd.2;
		return dt.date.day: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s day of the week
export fn weekday(dt: *datetime) int = {
	match (dt.date.weekday) {
	case void =>
		if (dt.date.epochal is void) {
			epochal(dt);
		};
		dt.date.weekday = calc_weekday(dt.date.epochal: int);
		return dt.date.weekday: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s ordinal day of the year
export fn yearday(dt: *datetime) int = {
	match (dt.date.yearday) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.month is void) {
			month(dt);
		};
		if (dt.date.day is void) {
			day(dt);
		};
		dt.date.yearday = calc_yearday(
			dt.date.year: int,
			dt.date.month: int,
			dt.date.day: int,
		);
		return dt.date.yearday: int;
	case let yd: int =>
		return yd;
	};
};

// Evaluates a [[datetime]]'s ISO week-numbering year
export fn isoweekyear(dt: *datetime) int = {
	match (dt.date.isoweekyear) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.month is void) {
			month(dt);
		};
		if (dt.date.day is void) {
			day(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		dt.date.isoweekyear = calc_isoweekyear(
			dt.date.year: int,
			dt.date.month: int,
			dt.date.day: int,
			dt.date.weekday: int,
		);
		return dt.date.isoweekyear: int;
	case let iwy: int =>
		return iwy;
	};
};

// Evaluates a [[datetime]]'s Gregorian week
export fn week(dt: *datetime) int = {
	match (dt.date.week) {
	case void =>
		if (dt.date.yearday is void) {
			yearday(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		dt.date.week = calc_week(
			dt.date.yearday: int,
			dt.date.weekday: int,
		);
		return dt.date.week: int;
	case let w: int =>
		return w;
	};
};

// Evaluates a [[datetime]]'s ISO week
export fn isoweek(dt: *datetime) int = {
	match (dt.date.isoweek) {
	case void =>
		if (dt.date.year is void) {
			year(dt);
		};
		if (dt.date.week is void) {
			week(dt);
		};
		if (dt.date.weekday is void) {
			weekday(dt);
		};
		if (dt.date.yearday is void) {
			yearday(dt);
		};
		dt.date.isoweek = calc_isoweek(
			dt.date.year: int,
			dt.date.week: int,
			dt.date.weekday: int,
			dt.date.yearday: int,
		);
		return dt.date.isoweek: int;
	case let iw: int =>
		return iw;
	};
};


//
// time-like
//

// Evaluates a [[datetime]]'s hour of the day
export fn hour(dt: *datetime) int = {
	match (dt.time.hour) {
	case void =>
		abort("TODO");
	case let h: int =>
		return h;
	};
};

// Evaluates a [[datetime]]'s minute of the hour
export fn min(dt: *datetime) int = {
	match (dt.time.min) {
	case void =>
		abort("TODO");
	case let m: int =>
		return m;
	};
};

// Evaluates a [[datetime]]'s second of the minute
export fn sec(dt: *datetime) int = {
	match (dt.time.sec) {
	case void =>
		abort("TODO");
	case let s: int =>
		return s;
	};
};

// Evaluates a [[datetime]]'s nanosecond of the second
export fn nsec(dt: *datetime) int = {
	match (dt.time.nsec) {
	case void =>
		abort("TODO");
	case let n: int =>
		return n;
	};
};

//	// Converts a [[datetime]] to a [[chrono::moment]].
//	// Fails if there is insufficient information in the [[datetime]].
//	export fn conv_datetime_moment(dt: datetime) (chrono::moment | errors::invalid) = {
//		const d = conv_localdate_epochal(dt.date)?;
//		const t = conv_localtime_time(dt.time)?;
//		const m = chrono::moment {
//			date = d,
//			time = t,
//			loc = chrono::local, // TODO
//		};
//		return m;
//	};

//	// Converts a [[chrono::moment]] to a [[datetime]]
//	export fn conv_moment_datetime(m: chrono::moment, dt: *datetime) void = {
//		conv_epochal_localdate(m.date, &(dt.date), &localdate {
//			// TODO: reconcile, add more fields when ready
//			year = 0,
//			month = 0,
//			day = 0,
//			...
//		});
//	
//		const lt = conv_time_localtime(m.time);
//		dt.time = lt;
//	
//		dt.loc = chrono::local; // TODO
//		return dt;
//	};
