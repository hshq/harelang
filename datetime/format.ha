// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021-2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use ascii;
use errors;
use fmt;
use io;
use strconv;
use strings;
use strio;
use time::chrono;

// [[datetime::format]] layout for the email date format.
export def EMAIL: str = "%a, %d %b %Y %H:%M:%S %z";

// [[datetime::format]] layout for the email date format, with zone offset and
// zone abbreviation.
export def EMAILZ: str = "%a, %d %b %Y %H:%M:%S %z %Z";

// [[datetime::format]] layout partly compatible with the default layout format
// for the POSIX locale. %d is used in place of POSIX %e.
export def POSIX: str = "%a %b %d %H:%M:%S %Z %Y";
// TODO: Actually implement '%e' and thus the POSIX layout format?

// [[datetime::format]] layout compatible with RFC 3339.
export def RFC3339: str = "%Y-%m-%dT%H:%M:%S%z";

// [[datetime::format]] layout for a simple timestamp.
export def STAMP: str = "%Y-%m-%d %H:%M:%S";

// [[datetime::format]] layout for a simple timestamp with nanoseconds.
export def STAMP_NANO: str = "%Y-%m-%d %H:%M:%S.%N";

// [[datetime::format]] layout for a simple timestamp with nanoseconds,
// zone offset, zone abbreviation, and locality.
export def STAMP_NOZL: str = "%Y-%m-%d %H:%M:%S.%N %z %Z %L";

def WEEKDAYS: [_]str = [
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday",
	"Sunday",
];

def WEEKDAYS_SHORT: [_]str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

def MONTHS: [_]str = [
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
];

def MONTHS_SHORT: [_]str = [
	"Jan", "Feb", "Mar",
	"Apr", "May", "Jun",
	"Jul", "Aug", "Sep",
	"Oct", "Nov", "Dec",
];

// TODO: Make format() accept parameters of type (datetime | period), using the
// "intervals" standard representation provided by ISO 8601?
//
// See https://en.wikipedia.org/wiki/ISO_8601#Time_intervals
//
// Ticket: https://todo.sr.ht/~sircmpwn/hare/650

// Formats a [[datetime]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
export fn bsformat(
	buf: []u8,
	layout: str,
	dt: *datetime,
) (str | invalid | io::error) = {
	let sink = strio::fixed(buf);
	format(&sink, layout, dt)?;
	return strio::string(&sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
export fn asformat(layout: str, dt: *datetime) (str | invalid | io::error) = {
	let sink = strio::dynamic();
	format(&sink, layout, dt)?;
	return strio::string(&sink);
};

fn fmtout(out: io::handle, r: rune, dt: *datetime) (size | io::error) = {
	switch (r) {
	case 'a' =>
		return fmt::fprint(out, WEEKDAYS_SHORT[weekday(dt) - 1]);
	case 'A' =>
		return fmt::fprint(out, WEEKDAYS[weekday(dt) - 1]);
	case 'b' =>
		return fmt::fprint(out, MONTHS_SHORT[month(dt) - 1]);
	case 'B' =>
		return fmt::fprint(out, MONTHS[month(dt) - 1]);
	case 'd' =>
		return fmt::fprintf(out, "{:02}", day(dt));
	case 'F' =>
		return fmt::fprintf(out, "{:04}-{:02}-{:02}", year(dt), month(dt), day(dt));
	case 'H' =>
		return fmt::fprintf(out, "{:02}", hour(dt));
	case 'I' =>
		return fmt::fprintf(out, "{:02}", hour12(dt));
	case 'j' =>
		return fmt::fprint(out, strconv::itos(yearday(dt)));
	case 'L' =>
		return fmt::fprint(out, dt.loc.name);
	case 'm' =>
		return fmt::fprintf(out, "{:02}", month(dt));
	case 'M' =>
		return fmt::fprintf(out, "{:02}", minute(dt));
	case 'N' =>
		return fmt::fprintf(out, "{:09}", strconv::itos(nanosecond(dt)));
	case 'p' =>
		const s = if (hour(dt) < 12) {
			yield "AM";
		} else {
			yield "PM";
		};
		return fmt::fprint(out, s);
	case 's' =>
		return fmt::fprintf(out, "{:02}", epochunix(dt));
	case 'S' =>
		return fmt::fprintf(out, "{:02}", second(dt));
	case 'T' =>
		return fmt::fprintf(out, "{:02}:{:02}:{:02}", hour(dt), minute(dt), second(dt));
	case 'u' =>
		return fmt::fprint(out, strconv::itos(weekday(dt)));
	case 'U' =>
		return fmt::fprintf(out, "{:02}", _sundayweek(dt));
	case 'w' =>
		return fmt::fprint(out, strconv::itos(weekday(dt) % 7));
	case 'W' =>
		return fmt::fprintf(out, "{:02}", week(dt));
	case 'y' =>
		let year_str = strconv::itos(year(dt));
		year_str = strings::sub(year_str, len(year_str) - 2, strings::end);
		return fmt::fprint(out, year_str);
	case 'Y' =>
		return fmt::fprint(out, strconv::itos(year(dt)));
	case 'z' =>
		// TODO: test me
		let pm = '+';
		const z = if (dt.zone.zoffset >= 0) {
			yield calc_hmsn(dt.zone.zoffset);
		} else {
			pm = '-';
			yield calc_hmsn(-dt.zone.zoffset);
		};
		return fmt::fprintf(out, "{}{:02}{:02}", pm, z.0, z.1);
	case 'Z' =>
		return fmt::fprint(out, dt.zone.abbr);
	case '%' =>
		return fmt::fprint(out, "%");
	case =>
		abort("Invalid format string provided to datetime::format");
	};
};

// Formats a [[datetime]] according to a layout and writes to an [[io::handle]].
//
// The layout may contain any of the following format specifiers listed below.
// Implemented are a subset of the POSIX strftime(3) format specifiers, as well
// as some others. Use of unimplemented specifiers or an otherwise invalid
// layout will cause an abort.
//
// 	%% -- A literal '%' character.
// 	%a -- The abbreviated name of the day of the week.
// 	%A -- The full name of the day of the week.
// 	%b -- The abbreviated name of the month.
// 	%B -- The full name of the month.
// 	%d -- The day of the month (decimal, range 01 to 31).
// 	%F -- The full date, equivalent to %Y-%m-%d
// 	%H -- The hour of the day as from a 24-hour clock (range 00 to 23).
// 	%I -- The hour of the day as from a 12-hour clock (range 01 to 12).
// 	%j -- The ordinal day of the year (range 001 to 366).
// 	%L -- The locality's name (the timezone's identifier).
// 	%m -- The month (decimal, range 01 to 12).
// 	%M -- The minute (decimal, range 00 to 59).
// 	%N -- The nanosecond of the second (range 000000000 to 999999999).
// 	%p -- Either "AM" or "PM" according to the current time.
// 	      "AM" includes midnight, and "PM" includes noon.
// 	%s -- Number of seconds since 1970-01-01 00:00:00, the Unix epoch
// 	%S -- The second of the minute (range 00 to 60).
// 	%T -- The full time, equivalent to %H:%M:%S
// 	%u -- The day of the week (decimal, range 1 to 7). 1 represents Monday.
// 	%U -- The week number of the current year (range 00 to 53),
// 	      starting with the first Sunday as the first day of week 01.
// 	%w -- The day of the week (decimal, range 0 to 6). 0 represents Sunday.
// 	%W -- The week number of the current year (range 00 to 53),
// 	      starting with the first Monday as the first day of week 01.
// 	%y -- The year without the century digits (range 00 to 99).
// 	%Y -- The year.
// 	%z -- The observed zone offset.
// 	%Z -- The observed zone abbreviation.
//
export fn format(
	h: io::handle,
	layout: str,
	dt: *datetime
) (size | invalid | io::error) = {
	const iter = strings::iter(layout);
	let escaped = false;
	let n = 0z;
	for (true) {
		let r: rune = match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			yield r;
		};

		if (escaped) {
			escaped = false;
			n += fmtout(h, r, dt)?;
		} else {
			if (r == '%') {
				escaped = true;
			} else {
				strio::appendrune(h, r)?;
			};
		};
	};
	return n;
};

fn get_default_locale_string_index(iter: *strings::iterator, list: []str) (int | invalid) = {
	const name = strings::iterstr(iter);
	if (len(name) == 0) {
		return invalid;
	};
	for(let i = 0z; i < len(list); i += 1) {
		if (strings::hasprefix(name, list[i])) {
			// Consume name
			for (let j = 0z; j < len(list[i]); j += 1) {
				strings::next(iter);
			};
			return (i: int) + 1;
		};
	};
	return invalid;
};

fn get_max_n_digits(iter: *strings::iterator, n: uint) (int | invalid) = {
	let buf: [64]u8 = [0...];
	let bufstr = strio::fixed(buf);
	for (let i = 0z; i < n; i += 1) {
		let r: rune = match (strings::next(iter)) {
			case void =>
				break;
			case let r: rune =>
				yield r;
		};
		if (!ascii::isdigit(r)) {
			strings::prev(iter);
			break;
		};
		match (strio::appendrune(&bufstr, r)) {
		case io::error =>
			return invalid;
		case =>
			void;
		};
	};
	return match (strconv::stoi(strio::string(&bufstr))) {
	case let res: int =>
		yield res;
	case =>
		yield invalid;
	};
};

fn eat_one_rune(iter: *strings::iterator, needle: rune) (uint | invalid) = {
	let s_r = match (strings::next(iter)) {
	case void =>
		return invalid;
	case let r: rune =>
		yield r;
	};
	if (s_r == needle) {
		return 1;
	} else {
		strings::prev(iter);
		return 0;
	};
};

fn clamp_int(i: int, min: int, max: int) int = {
	return if (i < min) {
		yield min;
	} else if (i > max) {
		yield max;
	} else {
		yield i;
	};
};

fn hour12(dt: *datetime) int = {
	let mod_hour = hour(dt) % 12;
	if (mod_hour == 0) {
		mod_hour = 12;
	};
	return mod_hour;
};

@test fn format() void = {
	const dt = new(chrono::UTC, 0, 1994, 1, 1, 2, 17, 5, 24)!;

	const cases = [
		// special characters
		("%%", "%"),
		// hour
		("%H", "02"),
		("%I", "02"),
		// minute
		("%M", "17"),
		// second
		("%S", "05"),
		// nanosecond
		("%N", "000000024"),
		// am/pm
		("%p", "AM"),
		// day
		("%d", "01"),
		// month
		("%m", "01"),
		// year
		("%Y", "1994"),
		("%y", "94"),
		// month name
		("%b", "Jan"),
		("%B", "January"),
		// weekday
		("%u", "6"),
		("%w", "6"),
		("%a", "Sat"),
		("%A", "Saturday"),
		// yearday
		("%j", "1"),
		// week
		("%W", "00"),
		// full date
		("%F", "1994-01-01"),
		// full time
		("%T", "02:17:05"),
		// Unix timestamp
		("%s", "757390625"),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const layout = cases[i].0;
		const expected = cases[i].1;
		const actual = asformat(layout, &dt)!;
		defer free(actual);
		if (actual != expected) {
			fmt::printfln(
				"expected format({}, &dt) to be {} but was {}",
				layout, expected, actual
			)!;
			abort();
		};
	};
};

// TODO: Refactor this once the rest of the parse() refactoring is done
// Ticket: https://todo.sr.ht/~sircmpwn/hare/648

// @test fn parse() void = {
// 	let dt = datetime {...};

// 	// General tests
// 	parse("%Y-%m-%d %H:%M:%S.%N", "1994-08-27 11:01:02.123", &dt)!;
// 	assert(dt.year as int == 1994 &&
// 		dt.month as int == 8 &&
// 		dt.day as int == 27 &&
// 		dt.hour as int == 11 &&
// 		dt.min as int == 1 &&
// 		dt.sec as int == 2 &&
// 		dt.nsec as int == 123, "invalid parsing results");

// 	// General errors
// 	assert(parse("%Y-%m-%d", "1a94-08-27", &dt) is invalid,
// 		"invalid datetime string did not throw error");

// 	assert(parse("%Y-%m-%d", "1994-123-27", &dt) is invalid,
// 		"invalid datetime string did not throw error");

// 	assert(parse("%Y-%m-%d", "a994-08-27", &dt) is invalid,
// 		"invalid datetime string did not throw error");

// 	// Basic specifiers
// 	parse("%a", "Tue", &dt)!;
// 	assert(dt.weekday as int == 2, "invalid parsing results");

// 	parse("%a %d", "Tue 27", &dt)!;
// 	assert(dt.weekday as int == 2 &&
// 		dt.day as int == 27, "invalid parsing results");

// 	parse("%A", "Tuesday", &dt)!;
// 	assert(dt.weekday as int == 2, "invalid parsing results");

// 	parse("%b", "Feb", &dt)!;
// 	assert(dt.month as int == 2, "invalid parsing results");

// 	parse("%B", "February", &dt)!;
// 	assert(dt.month as int == 2, "invalid parsing results");

// 	parse("%I", "14", &dt)!;
// 	assert(dt.hour as int == 2, "invalid parsing results");

// 	parse("%j", "123", &dt)!;
// 	assert(dt.yearday as int == 123, "invalid parsing results");

// 	parse("%H %p", "6 AM", &dt)!;
// 	assert(dt.hour as int == 6, "invalid parsing results");

// 	parse("%H %p", "6 PM", &dt)!;
// 	assert(dt.hour as int == 18, "invalid parsing results");

// 	assert(parse("%H %p", "13 PM", &dt) is invalid,
// 		"invalid parsing results");

// 	assert(parse("%H %p", "PM 6", &dt) is invalid,
// 		"invalid parsing results");

// 	parse("%u", "7", &dt)!;
// 	assert(dt.weekday as int == 7, "invalid parsing results");

// 	parse("%U", "2", &dt)!;
// 	assert(dt.week as int == 2, "invalid parsing results");

// 	parse("%U", "99", &dt)!;
// 	assert(dt.week as int == 53, "invalid parsing results");

// 	parse("%w", "0", &dt)!;
// 	assert(dt.weekday as int == 7, "invalid parsing results");

// 	parse("%W", "2", &dt)!;
// 	assert(dt.week as int == 2, "invalid parsing results");
// };
