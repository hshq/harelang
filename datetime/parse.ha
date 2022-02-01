use errors;
use strings;

// Parses a datetime string into a [[mock]], using a "layout" format string
// with a subset of specifiers from POSIX strptime(3). Partial, incremental
// parsing is possible.
//
// 	datetime::parse(&mok, "%Y-%m-%d", "2038-01-19");
// 	datetime::parse(&mok, "%H:%M:%S", "03:14:07");
//
export fn parse(mok: *mock, layout: str, s: str) (void | errors::invalid) = {
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
			mok.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS_SHORT[..])?;
		case 'A' =>
			mok.weekday = get_default_locale_string_index(
				&s_iter, WEEKDAYS[..])?;
		case 'b' =>
			mok.month = get_default_locale_string_index(
				&s_iter, MONTHS_SHORT[..])?;
		case 'B' =>
			mok.month = get_default_locale_string_index(
				&s_iter, MONTHS[..])?;
		case 'd' =>
			let max_n_digits = 2u;
			mok.day = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 1, 31);
		case 'H' =>
			let max_n_digits = 2u;
			mok.hour = clamp_int(
				get_max_n_digits(&s_iter, max_n_digits)?, 0, 23);
		case 'I' =>
			let max_n_digits = 2u;
			const hour = get_max_n_digits(&s_iter, max_n_digits);
			mok.hour = match (hour) {
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
			mok.yearday = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 1, 366);
		case 'm' =>
			mok.month = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 1, 12);
		case 'M' =>
			mok.min = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 59);
		case 'N' =>
			mok.nsec = clamp_int(
				get_max_n_digits(&s_iter, 3)?, 0, 999);
		case 'p' =>
			if (mok.hour is void) {
				// We can't change the hour's am/pm because we
				// have no hour.
				return errors::invalid;
			};
			const rest = strings::iter_str(&s_iter);
			if (strings::hasprefix(rest, "AM")) {
				if (mok.hour as int > 12) {
					// 13 AM?
					return errors::invalid;
				} else if (mok.hour as int == 12) {
					mok.hour = 0;
				};
			} else if (strings::hasprefix(rest, "PM")) {
				if (mok.hour as int > 12) {
					// 13 PM?
					return errors::invalid;
				} else if (mok.hour as int < 12) {
					mok.hour =
						(mok.hour as int) + 12;
				};
			} else {
				return errors::invalid;
			};
			strings::next(&s_iter);
			strings::next(&s_iter);
		case 'S' =>
			mok.sec = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 61);
		case 'u', 'w' =>
			mok.weekday = match (get_max_n_digits(&s_iter, 1)) {
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
			mok.week = clamp_int(
				get_max_n_digits(&s_iter, 2)?, 0, 53);
		case 'Y' =>
			mok.year = get_max_n_digits(&s_iter, 4)?;
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
