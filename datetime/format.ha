use ascii;
use errors;
use fmt;
use io;
use strconv;
use strings;
use strio;

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
	defer io::close(bufstr);
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
		match (strio::appendrune(bufstr, r)) {
		case io::error =>
			return errors::invalid;
		case =>
			void;
		};
	};
	return match (strconv::stoi(strio::string(bufstr))) {
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

// Parses a datetime string into a [[datetime::datetime]].
//
// The resulting [[datetime::datetime]] may not contain sufficient information
// to be valid. Incremental parsing of data is possible, but the caller should
// validate the [[datetime::datetime]] when appropriate.
export fn strptime(format: str, s: str, dt: *datetime) (void | errors::invalid) = {
	const format_iter = strings::iter(format);
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
			dt.date.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
		case 'A' =>
			// TODO: Localization
			dt.date.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS[..])?;
		case 'b', 'h' =>
			// TODO: Localization
			dt.date.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
		case 'B' =>
			// TODO: Localization
			dt.date.month = get_default_locale_string_index(
				&s_iter, MONTHS[..])?;
		case 'd', 'e' =>
			let max_n_digits = 2u;
			if (format_r == 'e') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			dt.date.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
		case 'G' =>
			dt.date.isoweekyear = get_max_n_digits(&s_iter, 4)?;
		case 'H', 'k' =>
			let max_n_digits = 2u;
			if (format_r == 'k') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			dt.time.hour = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 0, 23);
		case 'I', 'l' =>
			let max_n_digits = 2u;
			if (format_r == 'l') {
				max_n_digits -= eat_one_rune(&s_iter, ' ')?;
			};
			const hour = get_max_n_digits(&s_iter, max_n_digits);
			dt.time.hour = match (hour) {
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
			dt.date.yearday = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 1, 366);
		case 'm' =>
			dt.date.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
		case 'M' =>
			dt.time.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'n' =>
			eat_one_rune(&s_iter, '\n')?;
		case 'N' =>
			dt.time.nsec = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 0, 999);
		case 'p', 'P' =>
			// TODO: Localization
			if (dt.time.hour is void) {
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
				if (dt.time.hour as int > 12) {
					// 13 AM?
					return errors::invalid;
				} else if (dt.time.hour as int == 12) {
					dt.time.hour = 0;
				};
			} else if (strings::hasprefix(rest, prefix_pm)) {
				if (dt.time.hour as int > 12) {
					// 13 PM?
					return errors::invalid;
				} else if (dt.time.hour as int < 12) {
					dt.time.hour =
						(dt.time.hour as int) + 12;
				};
			} else {
				return errors::invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'S' =>
			dt.time.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
		case 't' =>
			eat_one_rune(&s_iter, '\t')?;
		case 'u', 'w' =>
			dt.date.weekday = match (get_max_n_digits(&s_iter, 1)) {
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
			dt.date.week = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'V' =>
			dt.date.isoweek = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'Y' =>
			dt.date.year = get_max_n_digits(&s_iter, 4)?;
		case 'z' =>
			// TODO
			continue;
		case '%' =>
			eat_one_rune(&s_iter, '%')?;

		// Expansion specifiers
		case 'c' =>
			// TODO: Localization
			dt.date.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after weekday")!;
				return errors::invalid;
			};
			dt.date.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after month")!;
				return errors::invalid;
			};
			const max_n_digits = 2 - eat_one_rune(&s_iter, ' ')?;
			dt.date.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after day")!;
				return errors::invalid;
			};
			dt.time.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				fmt::printfln("no : after hour")!;
				return errors::invalid;
			};
			dt.time.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				fmt::printfln("no : after minute")!;
				return errors::invalid;
			};
			dt.time.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				fmt::printfln("no space after sec")!;
				return errors::invalid;
			};
			dt.date.year = get_max_n_digits(&s_iter, 4)?;
		case 'D', 'x' =>
			// TODO: Localization for %x
			dt.date.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
			if (eat_one_rune(&s_iter, '/')? != 1) {
				return errors::invalid;
			};
			dt.date.day = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 31);
			if (eat_one_rune(&s_iter, '/')? != 1) {
				return errors::invalid;
			};
			dt.date.year = get_max_n_digits(&s_iter, 4)?;
		case 'F' =>
			dt.date.year = get_max_n_digits(&s_iter, 4)?;
			if (eat_one_rune(&s_iter, '-')? != 1) {
				return errors::invalid;
			};
			dt.date.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
			if (eat_one_rune(&s_iter, '-')? != 1) {
				return errors::invalid;
			};
			dt.date.day = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 31);
		case 'r' =>
			// TODO: Localization
			// Time
			dt.time.hour = match (get_max_n_digits(&s_iter, 2)) {
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
			dt.time.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			dt.time.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
			if (eat_one_rune(&s_iter, ' ')? != 1) {
				return errors::invalid;
			};
			let rest = strings::iter_str(&s_iter);
			// AM/PM
			if (strings::hasprefix(rest, "AM")) {
				if (dt.time.hour as int > 12) {
					// 13 AM?
					return errors::invalid;
				} else if (dt.time.hour as int == 12) {
					dt.time.hour = 0;
				};
			} else if (strings::hasprefix(rest, "PM")) {
				if (dt.time.hour as int > 12) {
					// 13 PM?
					return errors::invalid;
				} else if (dt.time.hour as int < 12) {
					dt.time.hour =
						(dt.time.hour as int) + 12;
				};
			} else {
				return errors::invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'R' =>
			dt.time.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			dt.time.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'T', 'X' =>
			// TODO: Localization for %X
			dt.time.hour = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 23);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			dt.time.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
			if (eat_one_rune(&s_iter, ':')? != 1) {
				return errors::invalid;
			};
			dt.time.sec = clamp_int(
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
export fn bstrftime(buf: []u8, format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::fixed(buf);
	defer io::close(sink);
	fmttime(sink, format, dt)?;
	return strio::string(sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
export fn strftime(format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::dynamic();
	fmttime(sink, format, dt)?;
	return strio::finish(sink);
};

// Formats a [[datetime]] and writes it into a [[io::handle]].
export fn fmttime(h: io::handle, format: str, dt: *datetime) (size | errors::invalid | io::error) = {
	const iter = strings::iter(format);
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
			yield strftime("%a %b %e %H:%M:%S %Y", dt)?;
		case 'C' =>
			yield strconv::itos(year(dt) / 100);
		case 'D' =>
			yield strftime("%m/%d/%y", dt)?;
		case 'd' =>
			yield fmt::asprintf("{:02}", day(dt));
		case 'e' =>
			yield fmt::asprintf("{:2}", day(dt));
		case 'F' =>
			yield strftime("%Y-%m-%d", dt)?;
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
			yield strconv::itos(nsec(dt));
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
			yield strftime("%I:%M:%S %p", dt)?;
		case 'R' =>
			yield strftime("%H:%M", dt)?;
		case 'S' =>
			yield fmt::asprintf("{:02}", sec(dt));
		case 't' =>
			yield "\t";
		case 'T' =>
			yield strftime("%H:%M:%S", dt)?;
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
			yield strftime("%m/%d/%y", dt)?;
		case 'X' =>
			// TODO: Localization
			yield strftime("%H:%M:%S", dt)?;
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
