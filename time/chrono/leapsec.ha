// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fs;
use io;
use os;
use strconv;
use strings;

// Hare uses raw leap second information when dealing with the UTC and TAI
// timescales. This information is source from a standard file installed at
// /usr/share/zoneinfo/leap-seconds.list, which itself is fetched from and
// periodically maintained at various observatories.
//
// https://data.iana.org/time-zones/code/leap-seconds.list
// https://www.ietf.org/timezones/data/leap-seconds.list
// ftp://ftp.nist.gov/pub/time/leap-seconds.list
// ftp://ftp.boulder.nist.gov/pub/time/leap-seconds.list
//
// This is in contrast to previous systems which rely on TZif files, which are
// installed typically at /usr/share/zoneinfo, as part of the "Olson" IANA
// Timezone database. These files couple timezone and leap second data.
//
// Depending on a system's installation, leap second information may be
// deliberately left out of the TZif files, or duplicated throughout. This
// design also inhibits our ambitions for dealing with multiple, dynamic
// timescales. Therefore, we have decided to take an alternative approach.

// Error initializing the [[utc]] [[timescale]].
type utciniterror = !(fs::error | io::error | utf8::invalid);

// The number of seconds between the years 1900 and 1970.
//
// This number is hypothetical since timekeeping before atomic clocks was not
// accurate enough to account for small changes in time.
export def SECS_1900_1970: i64 = 2208988800;

// UTC/TAI leap second data; UTC timestamps and their offsets from TAI.
// Sourced from [[UTC_LEAPSECS_PATH]].
let utc_leapsecs: [](i64, i64) = [];

let utc_isinitialized: bool = false;

@fini fn free_utc() void = {
	free(utc_leapsecs);
};

fn init_utc_leapsecs() (void | utciniterror) = {
	const file = os::open(UTC_LEAPSECS_PATH)?;
	defer io::close(file)!;
	parse_utc_leapsecs(file)?;
};

// Parse UTC/TAI leap second data from [[UTC_LEAPSECS_PATH]].
// See file for format details.
fn parse_utc_leapsecs(h: io::handle) (void | utf8::invalid | io::error) = {
	for (let line => bufio::read_line(h)?) {
		let line = strings::fromutf8(line)?;
		defer free(line);

		if (strings::hasprefix(line, '#')) {
			continue;
		};

		const iter = strings::iter(line);
		const secs = scan_number(&iter); scan_whitespace(&iter);
		const diff = scan_number(&iter);
		if (secs is void || diff is void) {
			continue;
		};

		let secs = secs as i64 - SECS_1900_1970;
		let diff = diff as i64;
		append(utc_leapsecs, (secs, diff));
	};
};

fn scan_number(iter: *strings::iterator) (i64 | void) = {
	let begin = *iter;

	for (let rn => strings::next(iter)) {
		switch (rn) {
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' =>
			continue;
		case =>
			strings::prev(iter);
			break;
		};
	};

	return strconv::stoi64(strings::slice(&begin, iter))!;
};

fn scan_whitespace(iter: *strings::iterator) void = {
	for (let rn => strings::next(iter)) {
		switch (rn) {
		case ' ', '\t' =>
			continue;
		case =>
			strings::prev(iter);
			return;
		};
	};
};
