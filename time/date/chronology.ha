// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use errors;
use time;
use time::chrono;

// These functions are renamed to avoid namespace conflicts, like in the
// parameters of the [[new]] function.

// Returns a [[date]]'s era.
export fn era(dt: *date) int = _era(dt);

// Returns a [[date]]'s year.
export fn year(dt: *date) int = _year(dt);

// Returns a [[date]]'s month of the year.
export fn month(dt: *date) int = _month(dt);

// Returns a [[date]]'s day of the month.
export fn day(dt: *date) int = _day(dt);

// Returns a [[date]]'s day of the week; Monday=0 to Sunday=6.
export fn weekday(dt: *date) int = _weekday(dt);

// Returns a [[date]]'s ordinal day of the year.
export fn yearday(dt: *date) int = _yearday(dt);

// Returns a [[date]]'s ISO week-numbering year.
export fn isoweekyear(dt: *date) int = _isoweekyear(dt);

// Returns a [[date]]'s Gregorian week starting Monday.
export fn week(dt: *date) int = _week(dt);

// Returns a [[date]]'s Gregorian week starting Sunday.
export fn sundayweek(dt: *date) int = _sundayweek(dt);

// Returns a [[date]]'s ISO week.
export fn isoweek(dt: *date) int = _isoweek(dt);

// Returns a [[date]]'s hour of the day.
export fn hour(dt: *date) int = _hour(dt);

// Returns a [[date]]'s minute of the hour.
export fn minute(dt: *date) int = _minute(dt);

// Returns a [[date]]'s second of the minute.
export fn second(dt: *date) int = _second(dt);

// Returns a [[date]]'s nanosecond of the second.
export fn nanosecond(dt: *date) int = _nanosecond(dt);

fn _era(dt: *date) int = {
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

fn _year(dt: *date) int = {
	match (dt.year) {
	case void =>
		const ymd = calc_ymd(chrono::date(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.year: int;
	case let y: int =>
		return y;
	};
};

fn _month(dt: *date) int = {
	match (dt.month) {
	case void =>
		const ymd = calc_ymd(chrono::date(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.month: int;
	case let y: int =>
		return y;
	};
};

fn _day(dt: *date) int = {
	match (dt.day) {
	case void =>
		const ymd = calc_ymd(chrono::date(dt));
		dt.year = ymd.0;
		dt.month = ymd.1;
		dt.day = ymd.2;
		return dt.day: int;
	case let y: int =>
		return y;
	};
};

fn _weekday(dt: *date) int = {
	match (dt.weekday) {
	case void =>
		dt.weekday = calc_weekday(chrono::date(dt));
		return dt.weekday: int;
	case let y: int =>
		return y;
	};
};

fn _yearday(dt: *date) int = {
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

fn _isoweekyear(dt: *date) int = {
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

fn _week(dt: *date) int = {
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

fn _sundayweek(dt: *date) int = {
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

fn _isoweek(dt: *date) int = {
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

fn _hour(dt: *date) int = {
	match (dt.hour) {
	case void =>
		const hmsn = calc_hmsn(chrono::time(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.hour: int;
	case let h: int =>
		return h;
	};
};

fn _minute(dt: *date) int = {
	match (dt.minute) {
	case void =>
		const hmsn = calc_hmsn(chrono::time(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.minute: int;
	case let m: int =>
		return m;
	};
};

fn _second(dt: *date) int = {
	match (dt.second) {
	case void =>
		const hmsn = calc_hmsn(chrono::time(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.second: int;
	case let s: int =>
		return s;
	};
};

fn _nanosecond(dt: *date) int = {
	match (dt.nanosecond) {
	case void =>
		const hmsn = calc_hmsn(chrono::time(dt));
		dt.hour = hmsn.0;
		dt.minute = hmsn.1;
		dt.second = hmsn.2;
		dt.nanosecond = hmsn.3;
		return dt.nanosecond: int;
	case let n: int =>
		return n;
	};
};
