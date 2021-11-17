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
	"Feburary",
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

// Parses a string into a [[datetime]]
export fn strptime(format: str, s: str, dt: *datetime) (void | errors::invalid) = {
	// TODO
	return void;
};

// Formats a [[datetime]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
// Fails if a particular datetime field is required but void.
export fn bstrftime(buf: []u8, format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::fixed(buf);
	defer io::close(sink);
	fmttime(sink, format, dt)?;
	return strio::string(sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
// Fails if a particular datetime field is required but void.
export fn strftime(format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::dynamic();
	fmttime(sink, format, dt)?;
	return strio::finish(sink);
};

// Formats a [[datetime]] and writes it into a [[io::handle]].
// Fails a particular field is required but void.
export fn fmttime(h: io::handle, format: str, dt: *datetime) (size | errors::invalid | io::error) = {
	let iter = strings::iter(format);
	let escaped = false;
	let n = 0z;
	for (true) {
		let r: rune = match (strings::next(&iter)) {
		case void =>
			break;
		case r: rune =>
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
			yield WEEKDAYS_SHORT[weekday(dt) - 1];
		case 'A' =>
			yield WEEKDAYS[weekday(dt) - 1];
		case 'b' =>
			yield MONTHS_SHORT[month(dt) - 1];
		case 'h' =>
			yield strftime("%b", dt)?;
		case 'B' =>
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
