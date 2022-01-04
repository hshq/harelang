use errors;
use time;
use time::chrono;

// Hare internally uses the Unix epoch (1970-01-01) for calendrical logic. Here
// we provide useful constant for working with the proleptic Gregorian calendar,
// as offsets from the Hare epoch.

// The Hare epoch of the Julian Day Number
export def EPOCH_JULIAN: i64 = -2440588;

// The Hare epoch of the Common Era
export def EPOCH_COMMONERA: i64 = -719164;


//
// date-like
//

// Evaluates a [[datetime]]'s number of days since the calendar epoch 0000-01-01
export fn epochal(dt: *datetime) chrono::epochal = {
	return dt.date - EPOCH_COMMONERA;
};

// Evaluates a [[datetime]]'s era
export fn era(dt: *datetime) int = {
	match (dt.era) {
	case void =>
		if (dt.year is void) {
			dt.year = year(dt);
		};
		dt.era = calc_era(dt.year: int);
		return dt.era: int;
	case let a: int =>
		return a;
	};
};

// Evaluates a [[datetime]]'s year
export fn year(dt: *datetime) int = {
	match (dt.year) {
	case void =>
		const ymd = calc_ymd(dt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.year: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s month of the year
export fn month(dt: *datetime) int = {
	match (dt.month) {
	case void =>
		const ymd = calc_ymd(dt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.month: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s day of the month
export fn day(dt: *datetime) int = {
	match (dt.day) {
	case void =>
		const ymd = calc_ymd(dt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.day: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s day of the week
export fn weekday(dt: *datetime) int = {
	match (dt.weekday) {
	case void =>
		dt.weekday = calc_weekday(dt.date: chrono::epochal);
		return dt.weekday: int;
	case let y: int =>
		return y;
	};
};

// Evaluates a [[datetime]]'s ordinal day of the year
export fn yearday(dt: *datetime) int = {
	match (dt.yearday) {
	case void =>
		if (dt.year is void) {
			year(dt);
		};
		if (dt.month is void) {
			month(dt);
		};
		if (dt.day is void) {
			day(dt);
		};
		dt.yearday = calc_yearday(
			dt.year: int,
			dt.month: int,
			dt.day: int,
		);
		return dt.yearday: int;
	case let yd: int =>
		return yd;
	};
};

// Evaluates a [[datetime]]'s ISO week-numbering year
export fn isoweekyear(dt: *datetime) int = {
	match (dt.isoweekyear) {
	case void =>
		if (dt.year is void) {
			year(dt);
		};
		if (dt.month is void) {
			month(dt);
		};
		if (dt.day is void) {
			day(dt);
		};
		if (dt.weekday is void) {
			weekday(dt);
		};
		dt.isoweekyear = calc_isoweekyear(
			dt.year: int,
			dt.month: int,
			dt.day: int,
			dt.weekday: int,
		);
		return dt.isoweekyear: int;
	case let iwy: int =>
		return iwy;
	};
};

// Evaluates a [[datetime]]'s Gregorian week
export fn week(dt: *datetime) int = {
	match (dt.week) {
	case void =>
		if (dt.yearday is void) {
			yearday(dt);
		};
		if (dt.weekday is void) {
			weekday(dt);
		};
		dt.week = calc_week(
			dt.yearday: int,
			dt.weekday: int,
		);
		return dt.week: int;
	case let w: int =>
		return w;
	};
};

// Evaluates a [[datetime]]'s ISO week
export fn isoweek(dt: *datetime) int = {
	match (dt.isoweek) {
	case void =>
		if (dt.year is void) {
			year(dt);
		};
		if (dt.week is void) {
			week(dt);
		};
		if (dt.weekday is void) {
			weekday(dt);
		};
		if (dt.yearday is void) {
			yearday(dt);
		};
		dt.isoweek = calc_isoweek(
			dt.year: int,
			dt.week: int,
			dt.weekday: int,
			dt.yearday: int,
		);
		return dt.isoweek: int;
	case let iw: int =>
		return iw;
	};
};


//
// time-like
//

// Evaluates a [[datetime]]'s hour of the day
export fn hour(dt: *datetime) int = {
	match (dt.hour) {
	case void =>
		const hmsn = calc_hmsn(dt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.hour: int;
	case let h: int =>
		return h;
	};
};

// Evaluates a [[datetime]]'s minute of the hour
export fn min(dt: *datetime) int = {
	match (dt.min) {
	case void =>
		const hmsn = calc_hmsn(dt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.min: int;
	case let m: int =>
		return m;
	};
};

// Evaluates a [[datetime]]'s second of the minute
export fn sec(dt: *datetime) int = {
	match (dt.sec) {
	case void =>
		const hmsn = calc_hmsn(dt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.sec: int;
	case let s: int =>
		return s;
	};
};

// Evaluates a [[datetime]]'s nanosecond of the second
export fn nsec(dt: *datetime) int = {
	match (dt.nsec) {
	case void =>
		const hmsn = calc_hmsn(dt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.nsec: int;
	case let n: int =>
		return n;
	};
};
