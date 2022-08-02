// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use errors;
use time;
use time::chrono;

// These functions are renamed to avoid namespace conflicts, like in the
// parameters of the [[new]] function.

// TODO: For [[epochal]]: Use Hare epoch or Gregorian epoch? Make two function?
// TODO: Create an exported [[zeroweekday]] field function.

// Returns a [[datetime]]'s number of days since the calendar epoch 0000-01-01.
export fn epochal(dt: *datetime) chrono::date = _epochal(dt);

// Returns a [[datetime]]'s number of seconds since the Unix epoch 1970-01-01.
export fn epochunix(dt: *datetime) int = _epochunix(dt);

// Returns a [[datetime]]'s era.
export fn era(dt: *datetime) int = _era(dt);

// Returns a [[datetime]]'s year.
export fn year(dt: *datetime) int = _year(dt);

// Returns a [[datetime]]'s month of the year.
export fn month(dt: *datetime) int = _month(dt);

// Returns a [[datetime]]'s day of the month.
export fn day(dt: *datetime) int = _day(dt);

// Returns a [[datetime]]'s day of the week.
export fn weekday(dt: *datetime) int = _weekday(dt);

// Returns a [[datetime]]'s ordinal day of the year.
export fn yearday(dt: *datetime) int = _yearday(dt);

// Returns a [[datetime]]'s ISO week-numbering year.
export fn isoweekyear(dt: *datetime) int = _isoweekyear(dt);

// Returns a [[datetime]]'s Gregorian week starting Monday.
export fn week(dt: *datetime) int = _week(dt);

// Returns a [[datetime]]'s Gregorian week starting Sunday.
export fn sundayweek(dt: *datetime) int = _sundayweek(dt);

// Returns a [[datetime]]'s ISO week.
export fn isoweek(dt: *datetime) int = _isoweek(dt);

// Returns a [[datetime]]'s hour of the day.
export fn hour(dt: *datetime) int = _hour(dt);

// Returns a [[datetime]]'s minute of the hour.
export fn minute(dt: *datetime) int = _minute(dt);

// Returns a [[datetime]]'s second of the minute.
export fn second(dt: *datetime) int = _second(dt);

// Returns a [[datetime]]'s nanosecond of the second.
export fn nanosecond(dt: *datetime) int = _nanosecond(dt);

fn _epochal(dt: *datetime) chrono::date = {
	return chrono::getdate(dt) - EPOCHAL_GREGORIAN;
};

fn _epochunix(dt: *datetime) int = {
	return time::unix(*(dt: *time::instant)): int;
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
	match (dt.year) {
	case void =>
		const ymd = calc_ymd(chrono::getdate(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.year: int;
	case let y: int =>
		return y;
	};
};

fn _month(dt: *datetime) int = {
	match (dt.month) {
	case void =>
		const ymd = calc_ymd(chrono::getdate(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.month: int;
	case let y: int =>
		return y;
	};
};

fn _day(dt: *datetime) int = {
	match (dt.day) {
	case void =>
		const ymd = calc_ymd(chrono::getdate(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.day: int;
	case let y: int =>
		return y;
	};
};

fn _weekday(dt: *datetime) int = {
	match (dt.weekday) {
	case void =>
		dt.weekday = calc_weekday(chrono::getdate(dt));
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

fn _sundayweek(dt: *datetime) int = {
	match (dt.sundayweek) {
	case void =>
		if (dt.yearday is void) {
			_yearday(dt);
		};
		if (dt.weekday is void) {
			_weekday(dt);
		};
		dt.sundayweek = calc_sundayweek(
			dt.yearday: int,
			dt.weekday: int,
		);
		return dt.sundayweek: int;
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
		dt.isoweek = calc_isoweek(
			dt.year: int,
			dt.week: int,
		);
		return dt.isoweek: int;
	case let iw: int =>
		return iw;
	};
};

fn _hour(dt: *datetime) int = {
	match (dt.hour) {
	case void =>
		const hmsn = calc_hmsn(chrono::gettime(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.hour: int;
	case let h: int =>
		return h;
	};
};

fn _minute(dt: *datetime) int = {
	match (dt.minute) {
	case void =>
		const hmsn = calc_hmsn(chrono::gettime(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.minute: int;
	case let m: int =>
		return m;
	};
};

fn _second(dt: *datetime) int = {
	match (dt.second) {
	case void =>
		const hmsn = calc_hmsn(chrono::gettime(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.second: int;
	case let s: int =>
		return s;
	};
};

fn _nanosecond(dt: *datetime) int = {
	match (dt.nanosecond) {
	case void =>
		const hmsn = calc_hmsn(chrono::gettime(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.nanosecond: int;
	case let n: int =>
		return n;
	};
};
