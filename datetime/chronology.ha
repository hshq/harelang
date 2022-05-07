// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use errors;
use time;
use time::chrono;

// Functions renamed here to avoid namespace conflict, like in the parameters of
// the [[new]] function.

// Returns a [[datetime]]'s number of days since the calendar epoch 0000-01-01
export fn epochal(dt: *datetime) chrono::epochal = _epochal(dt);

// Returns a [[datetime]]'s era
export fn era(dt: *datetime) int = _era(dt);

// Returns a [[datetime]]'s year
export fn year(dt: *datetime) int = _year(dt);

// Returns a [[datetime]]'s month of the year
export fn month(dt: *datetime) int = _month(dt);

// Returns a [[datetime]]'s day of the month
export fn day(dt: *datetime) int = _day(dt);

// Returns a [[datetime]]'s day of the week
export fn weekday(dt: *datetime) int = _weekday(dt);

// Returns a [[datetime]]'s ordinal day of the year
export fn yearday(dt: *datetime) int = _yearday(dt);

// Returns a [[datetime]]'s ISO week-numbering year
export fn isoweekyear(dt: *datetime) int = _isoweekyear(dt);

// Returns a [[datetime]]'s Gregorian week
export fn week(dt: *datetime) int = _week(dt);

// Returns a [[datetime]]'s Gregorian week starting Sunday
export fn week_starting_sunday(dt: *datetime) int = _week_starting_sunday(dt);

// Returns a [[datetime]]'s ISO week
export fn isoweek(dt: *datetime) int = _isoweek(dt);

// Returns a [[datetime]]'s hour of the day
export fn hour(dt: *datetime) int = _hour(dt);

// Returns a [[datetime]]'s minute of the hour
export fn min(dt: *datetime) int = _min(dt);

// Returns a [[datetime]]'s second of the minute
export fn sec(dt: *datetime) int = _sec(dt);

// Returns a [[datetime]]'s nanosecond of the second
export fn nsec(dt: *datetime) int = _nsec(dt);


fn _epochal(dt: *datetime) chrono::epochal = {
	const ldt = transform(*dt, dt.zone.zoffset);
	return ldt.date - EPOCHAL_GREGORIAN;
};

fn _era(dt: *datetime) int = {
	match (dt.era) {
	case void =>
		if (dt.year is void) {
			dt.year = _year(dt);
		};
		dt.era = calc_era(dt.year: int);
		return dt.era: int;
	case let a: int =>
		return a;
	};
};

fn _year(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.year) {
	case void =>
		const ymd = calc_ymd(ldt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.year: int;
	case let y: int =>
		return y;
	};
};

fn _month(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.month) {
	case void =>
		const ymd = calc_ymd(ldt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.month: int;
	case let y: int =>
		return y;
	};
};

fn _day(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.day) {
	case void =>
		const ymd = calc_ymd(ldt.date: chrono::epochal);
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.day: int;
	case let y: int =>
		return y;
	};
};

fn _weekday(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.weekday) {
	case void =>
		dt.weekday = calc_weekday(ldt.date: chrono::epochal);
		return dt.weekday: int;
	case let y: int =>
		return y;
	};
};

fn _yearday(dt: *datetime) int = {
	match (dt.yearday) {
	case void =>
		if (dt.year is void) {
			_year(dt);
		};
		if (dt.month is void) {
			_month(dt);
		};
		if (dt.day is void) {
			_day(dt);
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

fn _isoweekyear(dt: *datetime) int = {
	match (dt.isoweekyear) {
	case void =>
		if (dt.year is void) {
			_year(dt);
		};
		if (dt.month is void) {
			_month(dt);
		};
		if (dt.day is void) {
			_day(dt);
		};
		if (dt.weekday is void) {
			_weekday(dt);
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

fn _week(dt: *datetime) int = {
	match (dt.week) {
	case void =>
		if (dt.yearday is void) {
			_yearday(dt);
		};
		if (dt.weekday is void) {
			_weekday(dt);
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

fn _week_starting_sunday(dt: *datetime) int = {
	match (dt.week) {
	case void =>
		if (dt.yearday is void) {
			_yearday(dt);
		};
		if (dt.weekday is void) {
			_weekday(dt);
		};
		dt.weeksunday = calc_week_starting_sunday(
			dt.yearday: int,
			dt.weekday: int,
		);
		return dt.weeksunday: int;
	case let w: int =>
		return w;
	};
};

fn _isoweek(dt: *datetime) int = {
	match (dt.isoweek) {
	case void =>
		if (dt.year is void) {
			_year(dt);
		};
		if (dt.week is void) {
			_week(dt);
		};
		if (dt.weekday is void) {
			_weekday(dt);
		};
		if (dt.yearday is void) {
			_yearday(dt);
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

fn _hour(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.hour) {
	case void =>
		const hmsn = calc_hmsn(ldt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.hour: int;
	case let h: int =>
		return h;
	};
};

fn _min(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.min) {
	case void =>
		const hmsn = calc_hmsn(ldt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.min: int;
	case let m: int =>
		return m;
	};
};

fn _sec(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.sec) {
	case void =>
		const hmsn = calc_hmsn(ldt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.sec: int;
	case let s: int =>
		return s;
	};
};

fn _nsec(dt: *datetime) int = {
	const ldt = transform(*dt, dt.zone.zoffset);
	match (dt.nsec) {
	case void =>
		const hmsn = calc_hmsn(ldt.time: time::duration);
		dt.hour = hmsn.0;
		dt.min = hmsn.1;
		dt.sec = hmsn.2;
		dt.nsec = hmsn.3;
		return dt.nsec: int;
	case let n: int =>
		return n;
	};
};
