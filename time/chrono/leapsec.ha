// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
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
type utciniterror = !(fs::error | io::error | encoding::utf8::invalid);

// The number of seconds between the years 1900 and 1970. This number is
// deliberately hypothetical since timekeeping before atomic clocks was not
// accurate enough to account for small changes in time.
export def SECS_1900_1970: i64 = 2208988800;

// The filepath of the system's "leap-seconds.list" file, which contains UTC/TAI
// leap second data.
export def UTC_LEAPSECS_FILE: str = "/usr/share/zoneinfo/leap-seconds.list";

// UTC/TAI leap second data; UTC timestamps and their offsets from TAI.
// Sourced from [[UTC_LEAPSECS_FILE]].
let utc_leapsecs: [](i64, i64) = [];

let utc_isinitialized: bool = false;

// Initializes the [[utc]] [[timescale]].
@init fn init_utc() void = {
	os::init_cwd();
	match (init_utc_leapsecs()) {
	case void =>
		utc_isinitialized = true;
	case =>
		return;
	};
};

@fini fn free_utc() void = {
	free(utc_leapsecs);
};

fn init_utc_leapsecs() (void | utciniterror) = {
	const file = os::open(UTC_LEAPSECS_FILE)?;
	defer io::close(file)!;
	parse_utc_leapsecs(file, &utc_leapsecs)?;
};

// Parse UTC/TAI leap second data from [[UTC_LEAPSECS_FILE]].
// See file for format details.
fn parse_utc_leapsecs(
	h: io::handle,
	leapsecs: *[](i64, i64),
) (void | encoding::utf8::invalid | io::error) = {
	for (true) {
		const line = match (bufio::scanline(h)) {
		case let err: io::error =>
			return err;
		case io::EOF =>
			return;
		case let line: []u8 =>
			yield strings::fromutf8(line)?;
		};
		defer free(line);
		if (strings::hasprefix(line, '#')) {
			continue;
		};
		const pair = strings::splitn(line, "\t", 3);
		defer free(pair);
		if (len(pair) < 2) {
			continue;
		};
		const a = strconv::stoi64(pair[0])!;
		const b = strconv::stoi64(pair[1])!;
		const a = a - SECS_1900_1970;
		const pair = (a: i64, b: i64);
		append(utc_leapsecs, pair);
	};
};
