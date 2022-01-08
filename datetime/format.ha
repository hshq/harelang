use ascii;
use errors;
use fmt;
use io;
use strconv;
use strings;
use strio;
use time::chrono;

// TODO: implement modern long form "{year}-{month}-{day}" syntax alongside
// POSIX strftime "%Y-%m-%d" syntax.

export def RFC3999: str = "%Y-%m-%dT%H:%M:%S%z";
export def EMAIL: str = "%a, %d %b %Y %H:%M:%S %z";
export def POSIX: str = "%a %b %e %H:%M:%S %Z %Y";
export def STAMP: str = "%Y-%m-%d %H:%M:%S";
export def STAMP_NANO: str = "%Y-%m-%d %H:%M:%S.%N";

def WEEKDAYS: [_]str = [
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday",
	"Sunday",
];

def WEEKDAYS_SHORT: [_]str = ["Mon", "Tue", "Wed", "Thu", "Fr", "Sat", "Sun"];

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

// Parses a datetime string into a [[builder]], using a "layout" format string
// with specifiers from POSIX strptime(3). Partial, incremental parsing is
// allowed.
//
// 	datetime::parse(&b, "%Y-%m-%d", "2038-01-19");
// 	datetime::parse(&b, "%H:%M:%S", "03:14:07");
//
export fn parse(b: *builder, layout: str, s: str) (void | errors::invalid) = {
	const format_iter = strings::iter(layout);
	const s_iter = strings::iter(s);
	let escaped = false;
	for (true) {
		let format_r: rune = match (strings::next(&format_iter)) {
		case void =>
			break;
		case let r: rune =>
			yield r;
		};

		if (!escaped && format_r == '%') {
			escaped = true;
			continue;
		};

		if (!escaped) {
			let s_r = match (strings::next(&s_iter)) {
			case void =>
				return errors::invalid;
			case let r: rune =>
				yield r;
			};
			if (s_r != format_r) {
				return errors::invalid;
			};
			continue;
		};

		escaped = false;
		switch (format_r) {
		// Basic specifiers
		case 'a' =>
			// TODO: Localization
			b.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
		case 'A' =>
			// TODO: Localization
			b.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS[..])?;
		case 'b', 'h' =>
			// TODO: Localization
			b.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
		case 'B' =>
			// TODO: Localization
			b.month = get_default_locale_string_index(
				&s_iter, MONTHS[..])?;
		case 'd', 'e' =>
			let max_n_digits = 2u;
			if (format_r == 'e') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			b.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
		case 'G' =>
			b.isoweekyear = get_max_n_digits(&s_iter, 4)?;
		case 'H', 'k' =>
			let max_n_digits = 2u;
			if (format_r == 'k') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			b.hour = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 0, 23);
		case 'I', 'l' =>
			let max_n_digits = 2u;
			if (format_r == 'l') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			const hour = get_max_n_digits(&s_iter, max_n_digits);
			b.hour = match (hour) {
			case let hour: int =>
				yield if (hour > 12) {
					yield clamp_int(hour - 12, 1, 12);
				} else {
					yield clamp_int(hour, 1, 12);
				};
			case =>
				return errors::invalid;
			};
		case 'j' =>
			b.yearday = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 1, 366);
		case 'm' =>
			b.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
		case 'M' =>
			b.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'n' =>
			eat_one_rune(&s_iter, '\n')?;
		case 'N' =>
			b.nsec = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 0, 999);
		case 'p', 'P' =>
			// TODO: Localization
			if (b.hour is void) {
				// We can't change the hour's am/pm because we
				// have no hour.
				return errors::invalid;
			};
			let rest = strings::iter_str(&s_iter);
			let prefix_am = if (format_r == 'p') {
				yield "AM";
			} else {
				yield "am";
			};
			let prefix_pm = if (format_r == 'p') {
				yield "PM";
			} else {
				yield "pm";
			};
			if (strings::hasprefix(rest, prefix_am)) {
				if (b.hour as int > 12) {
					// 13 AM?
					return errors::invalid;
				} else if (b.hour as int == 12) {
					b.hour = 0;
				};
			} else if (strings::hasprefix(rest, prefix_pm)) {
				if (b.hour as int > 12) {
					// 13 PM?
					return errors::invalid;
				} else if (b.hour as int < 12) {
					b.hour =
						(b.hour as int) + 12;
				};
			} else {
				return errors::invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'S' =>
			b.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
		case 't' =>
			eat_one_rune(&s_iter, '\t')?;
		case 'u', 'w' =>
			b.weekday = match (get_max_n_digits(&s_iter, 1)) {
			case let i: int =>
				yield if (format_r == 'w') {
					yield if (i == 0) {
						yield 7;
					} else {
						yield clamp_int(i, 1, 7);
					};
				} else {
					yield clamp_int(i, 1, 7);
				};
			case =>
				return errors::invalid;
			};
		case 'U', 'W' =>
			b.week = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'V' =>
			b.isoweek = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'Y' =>
			b.year = get_max_n_digits(&s_iter, 4)?;
		case 'z' =>
			// TODO
			continue;
		case '%' =>
			eat_one_rune(&s_iter, '%')?;

		// Expansion specifiers
		case 'c' =>
			// TODO: Localization
			b.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after weekday")!;
				return errors::invalid;
			};
			b.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after month")!;
				return errors::invalid;
			};
			const max_n_digits = 2 - eat_one_rune(&s_iter, ' ')?;
			b.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after day")!;
				return errors::invalid;
			};
			b.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				fmt::printfln("no : after hour")!;
				return errors::invalid;
			};
			b.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				fmt::printfln("no : after minute")!;
				return errors::invalid;
			};
			b.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after sec")!;
				return errors::invalid;
			};
			b.year = get_max_n_digits(&s_iter, 4)?;
		case 'D', 'x' =>
			// TODO: Localization for %x
			b.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
			if (eat_one_rune(&s_iter, '/')? != 1) {
				return errors::invalid;
			};
			b.day = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 31);
			if (eat_one_rune(&s_iter, '/')? != 1) {
				return errors::invalid;
			};
			b.year = get_max_n_digits(&s_iter, 4)?;
		case 'F' =>
			b.year = get_max_n_digits(&s_iter, 4)?;
			if (eat_one_rune(&s_iter, '-')? != 1) {
				return errors::invalid;
			};
			b.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
			if (eat_one_rune(&s_iter, '-')? != 1) {
				return errors::invalid;
			};
			b.day = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 31);
		case 'r' =>
			// TODO: Localization
			// Time
			b.hour = match (get_max_n_digits(&s_iter, 2)) {
			case let hour: int =>
				yield if (hour > 12) {
					yield clamp_int(hour - 12, 1, 12);
				} else {
					yield clamp_int(hour, 1, 12);
				};
			case =>
				return errors::invalid;
			};
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			b.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			b.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				return errors::invalid;
			};
			let rest = strings::iter_str(&s_iter);
			// AM/PM
			if (strings::hasprefix(rest, "AM")) {
				if (b.hour as int > 12) {
					// 13 AM?
					return errors::invalid;
				} else if (b.hour as int == 12) {
					b.hour = 0;
				};
			} else if (strings::hasprefix(rest, "PM")) {
				if (b.hour as int > 12) {
					// 13 PM?
					return errors::invalid;
				} else if (b.hour as int < 12) {
					b.hour =
						(b.hour as int) + 12;
				};
			} else {
				return errors::invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'R' =>
			b.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			b.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'T', 'X' =>
			// TODO: Localization for %X
			b.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			b.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			b.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);

		case =>
			// Ignore invalid specifier
			continue;
		};
	};
	return void;
};

// Formats a [[datetime]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
export fn bformat(buf: []u8, layout: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::fixed(buf);
	fmtstream(&sink, layout, dt)?;
	return strio::string(&sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
export fn format(layout: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::dynamic();
	fmtstream(&sink, layout, dt)?;
	return strio::string(&sink);
};

// Formats a [[datetime]] and writes to an [[io::handle]].
export fn fmtstream(h: io::handle, layout: str, dt: *datetime) (size | errors::invalid | io::error) = {
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

		if (!escaped && r == '%') {
			escaped = true;
			continue;
		};

		if (!escaped) {
			strio::appendrune(h, r)?;
			continue;
		};

		escaped = false;
		let s = switch (r) {
		case 'a' =>
			// TODO: Localization
			yield WEEKDAYS_SHORT[weekday(dt) - 1];
		case 'A' =>
			// TODO: Localization
			yield WEEKDAYS[weekday(dt) - 1];
		case 'b', 'h' =>
			// TODO: Localization
			yield MONTHS_SHORT[month(dt) - 1];
		case 'B' =>
			// TODO: Localization
			yield MONTHS[month(dt) - 1];
		case 'c' =>
			// TODO: Localization
			yield format("%a %b %e %H:%M:%S %Y", dt)?;
		case 'C' =>
			yield strconv::itos(year(dt) / 100);
		case 'D' =>
			yield format("%m/%d/%y", dt)?;
		case 'd' =>
			yield fmt::asprintf("{:02}", day(dt));
		case 'e' =>
			yield fmt::asprintf("{:2}", day(dt));
		case 'F' =>
			yield format("%Y-%m-%d", dt)?;
		case 'g' =>
			let year_str = strconv::itos(isoweekyear(dt));
			yield strings::sub(year_str,
				len(year_str) - 2, strings::end);
		case 'G' =>
			yield strconv::itos(isoweekyear(dt));
		case 'H' =>
			yield fmt::asprintf("{:02}", hour(dt));
		case 'I' =>
			let mod_hour = hour(dt) % 12;
			if (mod_hour == 0) {
				mod_hour = 12;
			};
			yield fmt::asprintf("{:02}", mod_hour);
		case 'j' =>
			yield strconv::itos(yearday(dt));
		case 'k' =>
			yield strconv::itos(hour(dt));
		case 'l' =>
			let mod_hour = hour(dt) % 12;
			if (mod_hour == 0) {
				mod_hour = 12;
			};
			yield strconv::itos(mod_hour);
		case 'm' =>
			yield fmt::asprintf("{:02}", month(dt));
		case 'M' =>
			yield fmt::asprintf("{:02}", min(dt));
		case 'n' =>
			yield "\n";
		case 'N' =>
			yield fmt::asprintf("{:09}", strconv::itos(nsec(dt)));
		case 'p' =>
			// TODO: Localization
			yield if (hour(dt) < 12) {
				yield "AM";
			} else {
				yield "PM";
			};
		case 'P' =>
			// TODO: Localization
			yield if (hour(dt) < 12) {
				yield "am";
			} else {
				yield "pm";
			};
		case 'r' =>
			// TODO: Localization
			yield format("%I:%M:%S %p", dt)?;
		case 'R' =>
			yield format("%H:%M", dt)?;
		case 'S' =>
			yield fmt::asprintf("{:02}", sec(dt));
		case 't' =>
			yield "\t";
		case 'T' =>
			yield format("%H:%M:%S", dt)?;
		case 'u' =>
			yield strconv::itos(weekday(dt));
		case 'U' =>
			// yield fmt::asprintf("{:02}", week_starting_sunday(dt));
			// TODO
			yield "";
		case 'V' =>
			yield fmt::asprintf("{:02}", isoweek(dt));
		case 'w' =>
			yield strconv::itos(weekday(dt) % 7);
		case 'W' =>
			yield fmt::asprintf("{:02}", week(dt));
		case 'x' =>
			// TODO: Localization
			yield format("%m/%d/%y", dt)?;
		case 'X' =>
			// TODO: Localization
			yield format("%H:%M:%S", dt)?;
		case 'y' =>
			let year_str = strconv::itos(year(dt));
			yield strings::sub(year_str,
				len(year_str) - 2, strings::end);
		case 'Y' =>
			yield strconv::itos(year(dt));
		case 'z' =>
			//yield get_tz_hhmm(dt);
			// TODO
			yield "";
		case 'Z' =>
			//yield get_tz_name(dt);
			// TODO
			yield "";
		case '%' =>
			yield "%";
		case =>
			// Pass-through invalid conversion specifier characters.
			strio::appendrune(h, '%')?;
			strio::appendrune(h, r)?;
			continue;
		};
		n += strio::concat(h, s)?;
	};
	return n;
};

fn get_default_locale_string_index(iter: *strings::iterator, list: []str) (int | errors::invalid) = {
	const name = strings::iter_str(iter);
	if (len(name) == 0) {
		return errors::invalid;
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
	return errors::invalid;
};

fn get_max_n_digits(iter: *strings::iterator, n: uint) (int | errors::invalid) = {
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
			return errors::invalid;
		case =>
			void;
		};
	};
	return match (strconv::stoi(strio::string(&bufstr))) {
	case let res: int =>
		yield res;
	case =>
		yield errors::invalid;
	};
};

fn eat_one_rune(iter: *strings::iterator, needle: rune) (uint | errors::invalid) = {
	let s_r = match (strings::next(iter)) {
	case void =>
		return errors::invalid;
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

// TODO: Refactor this once the rest of the parse() refactoring is done
// @test fn parse() void = {
// 	let dt = datetime {...};

// 	// General tests
// 	parse("%Y-%m-%d %H:%M:%S.%N", "1994-08-27 11:01:02.123", &dt)!;
// 	assert(dt.year as int == 1994 &&
// 		dt.month as int == 08 &&
// 		dt.day as int == 27 &&
// 		dt.hour as int == 11 &&
// 		dt.min as int == 01 &&
// 		dt.sec as int == 02 &&
// 		dt.nsec as int == 123, "invalid parsing results");

// 	parse("%k:%M:%S.%N%n%t%%", " 9:01:02.123\n\t%", &dt)!;
// 	assert(dt.hour as int == 9 &&
// 		dt.min as int == 01 &&
// 		dt.sec as int == 02 &&
// 		dt.nsec as int == 123, "invalid parsing results");

// 	parse("%G-%m-%e", "994-8- 9", &dt)!;
// 	assert(dt.isoweekyear as int == 994 &&
// 		dt.month as int == 8 &&
// 		dt.day as int == 9, "invalid parsing results");

// 	// General errors
// 	assert(parse("%Y-%m-%d", "1a94-08-27", &dt) is errors::invalid,
// 		"invalid datetime string did not throw error");

// 	assert(parse("%Y-%m-%d", "1994-123-27", &dt) is errors::invalid,
// 		"invalid datetime string did not throw error");

// 	assert(parse("%Y-%m-%d", "a994-08-27", &dt) is errors::invalid,
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

// 	parse("%h", "Feb", &dt)!;
// 	assert(dt.month as int == 2, "invalid parsing results");

// 	parse("%B", "February", &dt)!;
// 	assert(dt.month as int == 2, "invalid parsing results");

// 	parse("%I", "14", &dt)!;
// 	assert(dt.hour as int == 2, "invalid parsing results");

// 	parse("%j", "123", &dt)!;
// 	assert(dt.yearday as int == 123, "invalid parsing results");

// 	parse("%l", " 9", &dt)!;
// 	assert(dt.hour as int == 9, "invalid parsing results");

// 	parse("%H %p", "6 AM", &dt)!;
// 	assert(dt.hour as int == 6, "invalid parsing results");

// 	parse("%H %p", "6 PM", &dt)!;
// 	assert(dt.hour as int == 18, "invalid parsing results");

// 	assert(parse("%H %p", "13 PM", &dt) is errors::invalid,
// 		"invalid parsing results");

// 	assert(parse("%H %p", "PM 6", &dt) is errors::invalid,
// 		"invalid parsing results");

// 	parse("%H %P", "6 am", &dt)!;
// 	assert(dt.hour as int == 6, "invalid parsing results");

// 	parse("%u", "7", &dt)!;
// 	assert(dt.weekday as int == 7, "invalid parsing results");

// 	parse("%U", "2", &dt)!;
// 	assert(dt.week as int == 2, "invalid parsing results");

// 	parse("%U", "99", &dt)!;
// 	assert(dt.week as int == 53, "invalid parsing results");

// 	parse("%V", "12", &dt)!;
// 	assert(dt.isoweek as int == 12, "invalid parsing results");

// 	parse("%w", "0", &dt)!;
// 	assert(dt.weekday as int == 7, "invalid parsing results");

// 	parse("%W", "2", &dt)!;
// 	assert(dt.week as int == 2, "invalid parsing results");

// 	// Expansion specifiers
// 	parse("%c", "Tue Feb  2 22:12:50 1994", &dt)!;
// 	assert(dt.day as int == 2 &&
// 		dt.month as int == 2 &&
// 		dt.year as int == 1994 &&
// 		dt.weekday as int == 2 &&
// 		dt.hour as int == 22 &&
// 		dt.min as int == 12 &&
// 		dt.sec as int == 50, "invalid parsing results");

// 	parse("%D", "08/2/1994", &dt)!;
// 	assert(dt.day as int == 2 &&
// 		dt.month as int == 8 &&
// 		dt.year as int == 1994, "invalid parsing results");

// 	parse("%F", "1994-08-27", &dt)!;
// 	assert(dt.day as int == 27 &&
// 		dt.month as int == 08 &&
// 		dt.year as int == 1994, "invalid parsing results");

// 	parse("%r", "04:20:12 PM", &dt)!;
// 	assert(dt.hour as int == 16 &&
// 		dt.min as int == 20 &&
// 		dt.sec as int == 12, "invalid parsing results");

// 	parse("%r", "04:20:12 AM", &dt)!;
// 	assert(dt.hour as int == 04 &&
// 		dt.min as int == 20 &&
// 		dt.sec as int == 12, "invalid parsing results");

// 	parse("%R", "12:2", &dt)!;
// 	assert(dt.hour as int == 12 &&
// 		dt.min as int == 2, "invalid parsing results");

// 	parse("%T", "12:2:12", &dt)!;
// 	assert(dt.hour as int == 12 &&
// 		dt.min as int == 2 &&
// 		dt.sec as int == 12, "invalid parsing results");
// };
