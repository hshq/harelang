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

// [[format]] layout for an ISO week-numbering timestamp.
export def ISOWKSTAMP: str = "%G-W%V-%u %H:%M:%S";

// [[format]] layout for a friendly, comprehensive datetime.
export def JOURNAL: str = "%Y %b %d, %a %H:%M:%S %z %Z %L";

// [[format]] layout for a friendly, terse datetime.
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

// Formats a [[date]] according to a layout and writes to an [[io::handle]].
//
// The layout may contain any of the following format specifiers listed below.
// These specifiers emit 2 digit zero-padded decimals unless stated otherwise.
// Use of unimplemented specifiers or an invalid layout will cause an abort.
//
// - %% : A single literal '%' character.
// - %a : The day of the week, abbreviated name. ("Sun").
// - %A : The day of the week, full name. ("Sunday").
// - %b : The month, abbreviated name. ("Jan").
// - %B : The month, full name. ("January").
// - %C : The century (the year without the last 2 digits). ("20").
// - %d : The day of the month. Range 01 to 31. ("02").
// - %e : The day of the month. Range  1 to 31,
//        right-aligned, space-padded. (" 2").
// - %F : The full Gregorian calendar date.
//        Alias for "%Y-%m-%d". ("2000-01-02").
// - %G : The ISO week-numbering year. At least 4 digits.
//        ISO-years before the Common Era have a minus sign prefix. ("1999").
// - %H : The hour of the day of a 24-hour clock. Range 00 to 23. ("15").
// - %I : The hour of the day of a 12-hour clock. Range 01 to 12. ("03").
// - %j : The ordinal day of the year. 3 digits, range 001 to 366. ("002").
// - %L : The locality's name (the timezone identifier). ("Europe/Amsterdam").
// - %m : The month of the year. Range 01 to 12. ("01").
// - %M : The minute of the hour. Range 00 to 59. ("04").
// - %N : The nanosecond of the second. 9 digits,
//        range 000000000 to 999999999. ("600000000").
// - %p : The meridian indicator, either "AM" or "PM".
//        "AM" includes midnight, and "PM" includes noon.
// - %s : The number of seconds since the locality's epoch. ("946821845").
// - %S : The second of the minute. Range 00 to 59. ("05").
// - %T : The wall-time of a 24-hour clock without nanoseconds.
//        Alias for "%H:%M:%S". ("15:04:05").
// - %u : The day of the week. 1 digit, range 1 to 7, Monday to Sunday. ("7").
// - %U : The sunday-week of the year. Range 00 to 53.
//        The year's first Sunday is the first day of week 01. ("01").
// - %V : The week of the ISO week-numbering year. Range 01 to 53. ("52").
// - %w : The day of the sunday-week.
//        1 digit, range 0 to 6, Sunday to Saturday. ("0").
// - %W : The week of the year. Range 00 to 53.
//        The year's first Monday is the first day of week 01. ("00").
// - %y : The year's last 2 digits, no century digits. Range 00 to 99. ("00").
// - %Y : The year. At least 4 digits.
//        Years before the Common Era have a minus sign prefix. ("2000").
// - %z : The observed zone offset. ("+0100").
// - %Z : The observed zone abbreviation. ("CET").
export fn format(
	h: io::handle,
	layout: str,
	d: *date
) (size | io::error) = {
	let iter = strings::iter(layout);
	let z = 0z;
	for (let r => strings::next(&iter)) {
		if (r == '%') {
			match (strings::next(&iter)) {
			case let spec: rune =>
				z += fmtspec(h, spec, d)?;
			case done =>
				abort("layout has dangling '%'");
			};
		} else {
			z += memio::appendrune(h, r)?;
		};
	};
	return z;
};

fn fmtspec(out: io::handle, r: rune, d: *date) (size | io::error) = {
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
		return fmt::fprintf(out, "{:.4}-{:.2}-{:.2}",
			_year(d), _month(d), _day(d));
	case 'G' =>
		return fmt::fprintf(out, "{:.4}", _isoweekyear(d));
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
		return fmt::fprintf(out, "{:.2}", d.sec);
	case 'S' =>
		return fmt::fprintf(out, "{:.2}", _second(d));
	case 'T' =>
		return fmt::fprintf(out, "{:.2}:{:.2}:{:.2}",
			_hour(d), _minute(d), _second(d));
	case 'u' =>
		return fmt::fprintf(out, "{}", _weekday(d) + 1);
	case 'U' =>
		return fmt::fprintf(out, "{:.2}", _sundayweek(d));
	case 'V' =>
		return fmt::fprintf(out, "{:.2}", _isoweek(d));
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
		abort("layout has unrecognised specifier");
	};
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
