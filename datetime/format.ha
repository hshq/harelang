use ascii;
use errors;
use fmt;
use io;
use strconv;
use strings;
use strio;
use time::chrono;

export def RFC3339: str = "%Y-%m-%dT%H:%M:%S%z";
export def EMAIL: str = "%a, %d %b %Y %H:%M:%S %z";
export def POSIX: str = "%a %b %d %H:%M:%S %Z %Y";
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

// TODO: Document specifiers (%Y, %m, etc) used here, in README or otherwise.

// Parses a datetime string into a [[builder]], using a "layout" format string
// with a subset of specifiers from POSIX strptime(3). Partial, incremental
// parsing is allowed.
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
			b.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
		case 'A' =>
			b.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS[..])?;
		case 'b' =>
			b.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
		case 'B' =>
			b.month = get_default_locale_string_index(
				&s_iter, MONTHS[..])?;
		case 'd' =>
			let max_n_digits = 2u;
			b.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
		case 'H' =>
			let max_n_digits = 2u;
			b.hour = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 0, 23);
		case 'I' =>
			let max_n_digits = 2u;
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
		case 'N' =>
			b.nsec = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 0, 999);
		case 'p' =>
			if (b.hour is void) {
				// We can't change the hour's am/pm because we
				// have no hour.
				return errors::invalid;
			};
			const rest = strings::iter_str(&s_iter);
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
		case 'S' =>
			b.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
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
		case 'Y' =>
			b.year = get_max_n_digits(&s_iter, 4)?;
		case 'z' =>
			// TODO
			continue;
		case '%' =>
			eat_one_rune(&s_iter, '%')?;

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

fn fmt_specifier(r: rune, dt: *datetime) (str | errors::invalid | io::error) = {
	return switch (r) {
	case 'a' =>
		yield WEEKDAYS_SHORT[weekday(dt) - 1];
	case 'A' =>
		yield WEEKDAYS[weekday(dt) - 1];
	case 'b' =>
		yield MONTHS_SHORT[month(dt) - 1];
	case 'B' =>
		yield MONTHS[month(dt) - 1];
	case 'd' =>
		yield fmt::asprintf("{:02}", day(dt));
	case 'H' =>
		yield fmt::asprintf("{:02}", hour(dt));
	case 'I' =>
		yield fmt::asprintf("{:02}", hour12(dt));
	case 'j' =>
		yield strconv::itos(yearday(dt));
	case 'm' =>
		yield fmt::asprintf("{:02}", month(dt));
	case 'M' =>
		yield fmt::asprintf("{:02}", min(dt));
	case 'N' =>
		yield fmt::asprintf("{:09}", strconv::itos(nsec(dt)));
	case 'p' =>
		yield if (hour(dt) < 12) {
			yield "AM";
		} else {
			yield "PM";
		};
	case 'S' =>
		yield fmt::asprintf("{:02}", sec(dt));
	case 'u' =>
		yield strconv::itos(weekday(dt));
	case 'U' =>
		// yield fmt::asprintf("{:02}", week_starting_sunday(dt));
		// TODO
		yield "";
	case 'w' =>
		yield strconv::itos(weekday(dt) % 7);
	case 'W' =>
		yield fmt::asprintf("{:02}", week(dt));
	case 'y' =>
		let year_str = strconv::itos(year(dt));
		yield strings::sub(year_str, len(year_str) - 2, strings::end);
	case 'Y' =>
		yield strconv::itos(year(dt));
	case 'z' =>
		// TODO: test
		let pm = '+';
		const z = if (dt.zone.zoffset >= 0) {
			yield calc_hmsn(dt.zone.zoffset);
		} else {
			pm = '-';
			yield calc_hmsn(-dt.zone.zoffset);
		};
		yield fmt::asprintf("{}{:02}{:02}", pm, z.0, z.1);
	case 'Z' =>
		yield dt.zone.abbr;
	case '%' =>
		yield "%";
	case =>
		// Pass-through invalid conversion specifier
		// characters.
		const passthrough = strio::dynamic();
		strio::appendrune(&passthrough, '%')!;
		strio::appendrune(&passthrough, r)!;
		yield strio::string(&passthrough);
	};
};

// Formats a [[datetime]] and writes to an [[io::handle]].
export fn fmtstream(
	h: io::handle,
	layout: str,
	dt: *datetime
) (size | errors::invalid | io::error) = {
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
			n += strio::concat(h, fmt_specifier(r, dt)?)?;
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

fn hour12(dt: *datetime) int = {
	let mod_hour = hour(dt) % 12;
	if (mod_hour == 0) {
		mod_hour = 12;
	};
	return mod_hour;
};

@test fn format() void = {
	const dt = new(1994, 01, 01, 02, 17, 05, 24, 0, chrono::local)!;

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
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const layout = cases[i].0;
		const expected = cases[i].1;
		const actual = format(layout, &dt)!;
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

// 	assert(parse("%H %p", "13 PM", &dt) is errors::invalid,
// 		"invalid parsing results");

// 	assert(parse("%H %p", "PM 6", &dt) is errors::invalid,
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
