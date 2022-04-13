use ascii;
use errors;
use fmt;
use io;
use strconv;
use strings;
use strio;
use time::chrono;

export def EMAIL: str = "%a, %d %b %Y %H:%M:%S %z";
export def EMAILZ: str = "%a, %d %b %Y %H:%M:%S %z %Z";
export def POSIX: str = "%a %b %d %H:%M:%S %Z %Y";
export def RFC3339: str = "%Y-%m-%dT%H:%M:%S%z";
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

// TODO: Document specifiers (%Y, %m, etc) used here, in README or otherwise.

// TODO: Make format() accept parameters of type (datetime | period), using the
// "intervals" standard representation provided by ISO 8601?
//
// See https://en.wikipedia.org/wiki/ISO_8601#Time_intervals

// Formats a [[datetime]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
export fn bformat(buf: []u8, layout: str, dt: *datetime) (str | invalid | io::error) = {
	let sink = strio::fixed(buf);
	fmtstream(&sink, layout, dt)?;
	return strio::string(&sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
export fn format(layout: str, dt: *datetime) (str | invalid | io::error) = {
	let sink = strio::dynamic();
	fmtstream(&sink, layout, dt)?;
	return strio::string(&sink);
};

fn fmt_specifier(r: rune, dt: *datetime) (str | invalid | io::error) = {
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
	const dt = new(chrono::UTC, 0, 1994, 01, 01, 02, 17, 05, 24)!;

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
