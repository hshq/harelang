// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use fmt;
use io;
use memio;
use strings;
use time;
use time::chrono;

// [[format]] layout for the email date format.
export def EMAIL: str = "%a, %d %b %Y %H:%M:%S %z";

// [[format]] layout for the email date format, with zone offset and
// zone abbreviation.
export def EMAILZONE: str = "%a, %d %b %Y %H:%M:%S %z %Z";

// [[format]] layout for the POSIX locale's default date & time representation.
export def POSIX: str = "%a %b %e %H:%M:%S %Y";

// [[format]] layout compatible with RFC 3339.
export def RFC3339: str = "%Y-%m-%dT%H:%M:%S%z";

// [[format]] layout for a standard, collatable timestamp.
export def STAMP: str = "%Y-%m-%d %H:%M:%S";

// [[format]] layout for a standard, collatable timestamp with nanoseconds.
export def STAMPNANO: str = "%Y-%m-%d %H:%M:%S.%N";

// [[format]] layout for a standard, collatable timestamp with nanoseconds
// and zone offset.
export def STAMPZOFF: str = "%Y-%m-%d %H:%M:%S.%N %z";

// [[format]] layout for a standard, collatable timestamp with nanoseconds,
// zone offset, and zone abbreviation.
export def STAMPZONE: str = "%Y-%m-%d %H:%M:%S.%N %z %Z";

// [[format]] layout for a standard, collatable timestamp with nanoseconds,
// zone offset, zone abbreviation, and locality.
export def STAMPLOC: str = "%Y-%m-%d %H:%M:%S.%N %z %Z %L";

// [[format]] layout for a friendly, comprehensive, serializable datetime.
export def JOURNAL: str = "%Y %b %d, %a %H:%M:%S %z %Z %L";

// [[format]] layout for a friendly, terse, glanceable datetime.
export def WRIST: str = "%b-%d %a %H:%M %Z";

// [[format]] layout for a precise timescalar second and nanosecond.
export def QUARTZ: str = "%s.%N";

// [[format]] layout for a precise timescalar second, nanosecond,
// and zone offset.
export def QUARTZZOFF: str = "%s.%N%z";

// [[format]] layout for a precise timescalar second, nanosecond,
// and locality.
export def QUARTZLOC: str = "%s.%N:%L";

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

// TODO: Make format() accept parameters of type (date | period), using the
// "intervals" standard representation provided by ISO 8601?
//
// See https://en.wikipedia.org/wiki/ISO_8601#Time_intervals
//
// Ticket: https://todo.sr.ht/~sircmpwn/hare/650

// Formats a [[date]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
export fn bsformat(
	buf: []u8,
	layout: str,
	d: *date,
) (str | io::error) = {
	let sink = memio::fixed(buf);
	format(&sink, layout, d)?;
	return memio::string(&sink)!;
};

// Formats a [[date]] and writes it into a heap-allocated string.
// The caller must free the return value.
export fn asformat(layout: str, d: *date) (str | io::error) = {
	let sink = memio::dynamic();
	format(&sink, layout, d)?;
	return memio::string(&sink)!;
};

fn fmtout(out: io::handle, r: rune, d: *date) (size | io::error) = {
	switch (r) {
	case 'a' =>
		return fmt::fprint(out, WEEKDAYS_SHORT[_weekday(d)]);
	case 'A' =>
		return fmt::fprint(out, WEEKDAYS[_weekday(d)]);
	case 'b' =>
		return fmt::fprint(out, MONTHS_SHORT[_month(d) - 1]);
	case 'B' =>
		return fmt::fprint(out, MONTHS[_month(d) - 1]);
	case 'C' =>
		return fmt::fprintf(out, "{:.2}", _year(d) / 100);
	case 'd' =>
		return fmt::fprintf(out, "{:.2}", _day(d));
	case 'e' =>
		return fmt::fprintf(out, "{: 2}", _day(d));
	case 'F' =>
		return fmt::fprintf(out, "{:.4}-{:.2}-{:.2}", _year(d), _month(d), _day(d));
	case 'H' =>
		return fmt::fprintf(out, "{:.2}", _hour(d));
	case 'I' =>
		return fmt::fprintf(out, "{:.2}", (_hour(d) + 11) % 12 + 1);
	case 'j' =>
		return fmt::fprintf(out, "{:.3}", _yearday(d));
	case 'L' =>
		return fmt::fprint(out, d.loc.name);
	case 'm' =>
		return fmt::fprintf(out, "{:.2}", _month(d));
	case 'M' =>
		return fmt::fprintf(out, "{:.2}", _minute(d));
	case 'N' =>
		return fmt::fprintf(out, "{:.9}", _nanosecond(d));
	case 'p' =>
		return fmt::fprint(out, if (_hour(d) < 12) "AM" else "PM");
	case 's' =>
		return fmt::fprintf(out, "{:.2}", time::unix(*(d: *time::instant)));
	case 'S' =>
		return fmt::fprintf(out, "{:.2}", _second(d));
	case 'T' =>
		return fmt::fprintf(out, "{:.2}:{:.2}:{:.2}", _hour(d), _minute(d), _second(d));
	case 'u' =>
		return fmt::fprintf(out, "{}", _weekday(d) + 1);
	case 'U' =>
		return fmt::fprintf(out, "{:.2}", _sundayweek(d));
	case 'w' =>
		return fmt::fprintf(out, "{}", (_weekday(d) + 1) % 7);
	case 'W' =>
		return fmt::fprintf(out, "{:.2}", _week(d));
	case 'y' =>
		return fmt::fprintf(out, "{:.2}", _year(d) % 100);
	case 'Y' =>
		return fmt::fprintf(out, "{:.4}", _year(d));
	case 'z' =>
		const (sign, zo) = if (chrono::ozone(d).zoff >= 0) {
			yield ('+', calc_hmsn(chrono::ozone(d).zoff));
		} else {
			yield ('-', calc_hmsn(-chrono::ozone(d).zoff));
		};
		const (hr, mi) = (zo.0, zo.1);
		return fmt::fprintf(out, "{}{:.2}{:.2}", sign, hr, mi);
	case 'Z' =>
		return fmt::fprint(out, chrono::ozone(d).abbr);
	case '%' =>
		return fmt::fprint(out, "%");
	case =>
		abort("Invalid format string provided to time::date::format");
	};
};

// Formats a [[date]] according to a layout and writes to an [[io::handle]].
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
// 	%C -- The century digits (all but the last two digits of the year).
// 	%d -- The day of the month (decimal, range 01 to 31).
// 	%e -- The day of the month (decimal, range  1 to 31), left-padded space.
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
	d: *date
) (size | io::error) = {
	const iter = strings::iter(layout);
	let escaped = false;
	let n = 0z;
	for (let r => strings::next(&iter)) {
		if (escaped) {
			escaped = false;
			n += fmtout(h, r, d)?;
		} else {
			if (r == '%') {
				escaped = true;
			} else {
				memio::appendrune(h, r)?;
			};
		};
	};
	return n;
};

@test fn format() void = {
	const d = new(chrono::UTC, 0, 1994, 1, 1, 2, 17, 5, 24)!;

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
		// day
		("%e", " 1"),
		// month
		("%m", "01"),
		// year
		("%Y", "1994"),
		("%y", "94"),
		("%C", "19"),
		// month name
		("%b", "Jan"),
		("%B", "January"),
		// weekday
		("%u", "6"),
		("%w", "6"),
		("%a", "Sat"),
		("%A", "Saturday"),
		// yearday
		("%j", "001"),
		// week
		("%W", "00"),
		// full date
		("%F", "1994-01-01"),
		// full time
		("%T", "02:17:05"),
		// Unix timestamp
		("%s", "757390625"),
	];

	for (let (layout, expected) .. cases) {
		const actual = asformat(layout, &d)!;
		defer free(actual);
		if (actual != expected) {
			fmt::printfln(
				"expected format({}, &d) to be {} but was {}",
				layout, expected, actual
			)!;
			abort();
		};
	};
};
