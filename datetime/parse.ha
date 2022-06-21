// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021-2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use errors;
use strings;
use time;

// Parses a date/time string into a [[builder]], according to a layout format
// string with specifiers as documented under [[format]]. Partial, sequential,
// aggregative parsing is possible.
//
// 	datetime::parse(&builder, "%Y-%m-%d", "2038-01-19");
// 	datetime::parse(&builder, "%H:%M:%S", "03:14:07");
//
export fn parse(build: *builder, layout: str, s: str) (void | invalid) = {
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
				return invalid;
			case let r: rune =>
				yield r;
			};
			if (s_r != format_r) {
				return invalid;
			};
			continue;
		};

		escaped = false;
		switch (format_r) {
		// Basic specifiers
		case 'a' =>
			build.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
		case 'A' =>
			build.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS[..])?;
		case 'b' =>
			build.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
		case 'B' =>
			build.month = get_default_locale_string_index(
				&s_iter, MONTHS[..])?;
		case 'd' =>
			let max_n_digits = 2u;
			build.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
		case 'H' =>
			let max_n_digits = 2u;
			build.hour = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 0, 23);
		case 'I' =>
			let max_n_digits = 2u;
			const hour = get_max_n_digits(&s_iter, max_n_digits);
			build.hour = match (hour) {
			case let hour: int =>
				yield if (hour > 12) {
					yield clamp_int(hour - 12, 1, 12);
				} else {
					yield clamp_int(hour, 1, 12);
				};
			case =>
				return invalid;
			};
		case 'j' =>
			build.yearday = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 1, 366);
		case 'L' =>
			// TODO: Parse %L (locality/timezone name/ID).
			continue;
		case 'm' =>
			build.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
		case 'M' =>
			build.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'N' =>
			build.nsec = clamp_int(
				get_max_n_digits(&s_iter, 9)?, 0, 999999999);
		case 'p' =>
			if (build.hour is void) {
				// We can't change the hour's am/pm because we
				// have no hour.
				return invalid;
			};
			const rest = strings::iterstr(&s_iter);
			if (strings::hasprefix(rest, "AM")) {
				if (build.hour as int > 12) {
					// 13 AM?
					return invalid;
				} else if (build.hour as int == 12) {
					build.hour = 0;
				};
			} else if (strings::hasprefix(rest, "PM")) {
				if (build.hour as int > 12) {
					// 13 PM?
					return invalid;
				} else if (build.hour as int < 12) {
					build.hour =
						(build.hour as int) + 12;
				};
			} else {
				return invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'S' =>
			build.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
		case 'u', 'w' =>
			build.weekday = match (get_max_n_digits(&s_iter, 1)) {
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
				return invalid;
			};
		case 'U', 'W' =>
			build.week = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'Y' =>
			build.year = get_max_n_digits(&s_iter, 4)?;
		case 'z' =>
			const rest = strings::iterstr(&s_iter);
			if(strings::hasprefix(rest, 'Z') || strings::hasprefix(rest, 'z')) {
				build.zone.zoffset = 0;
			} else {
				const prefix = strings::next(&s_iter);
				build.zone.zoffset = get_max_n_digits(&s_iter, 2)? * time::HOUR;

				const rest = strings::iterstr(&s_iter);
				if(strings::hasprefix(rest, ":")) {
					strings::next(&s_iter);
				};

				build.zone.zoffset += get_max_n_digits(&s_iter, 2)? * time::MINUTE;

				if(prefix == '-') {
					build.zone.zoffset *= -1;
				};
			};
		case '%' =>
			eat_one_rune(&s_iter, '%')?;

		case =>
			// Ignore invalid specifier
			continue;
		};
	};
	return void;
};
