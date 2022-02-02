use bufio;
use fmt;
use io;
use os;
use strconv;
use strings;

// Hare uses raw leap second informtion when dealing with the UTC and TAI
// timescales. This information is source from a standard file installed at
// /usr/share/zoneinfo/leap-seconds.list, which itself is fetched from and
// periodically maintained at:
//
// <ftp://ftp.nist.gov/pub/time/leap-seconds.list>
// <ftp://ftp.boulder.nist.gov/pub/time/leap-seconds.list>
//
// This is in contrast to legacy systems which rely on TZif files, which are
// installed typically at /usr/share/zoneinfo, as part of the "Olson" IANA
// Timezone databse. These files couple timezone and leap second information
// into one datablock.
//
// Depending on a system's installation, leap second information may be
// deliberately left out of the TZif files, or duplicated throughout. This
// design also inhibits our ambitions for dealing with multiple, dynamic
// timescales. Therefore, we have decided to take an alternative approach.

// The filepath of the leap-seconds.list file
export def UTC_LEAPSECS_FILE: str = "/usr/share/zoneinfo/leap-seconds.list";

// UTC timestamps and their TAI offsets, sourced from leap-seconds.list
let utc_leapsecs: [](i64, i64) = [];

// TODO: BUG: Cannot compile harec2 with this line.
//@init fn init_utc_leapsecs() void = init_utc_leapsecs();

fn init_utc_leapsecs() void = {
	const file = os::open(UTC_LEAPSECS_FILE)!;
	read_leapsecfile(file, &utc_leapsecs)!;
};

fn read_leapsecfile(h: io::handle, leapsecs: *[](i64, i64)) (void | io::error) = {
	for (true) {
		const line = match (bufio::scanline(h)) {
		case let err: io::error =>
			return err;
		case io::EOF =>
			return;
		case let line: []u8 =>
			yield line;
		};
		const line = fmt::bsprint(line);
		if (strings::hasprefix(line, '#')) {
			continue;
		};
		const pair = strings::splitN(line, "\t", 3);
		if (len(pair) < 2) {
			continue;
		};
		const a = strconv::stoi64(pair[0])!;
		const b = strconv::stoi64(pair[1])!;
		const pair = (a: i64, b: i64);
		append(utc_leapsecs, pair);
	};
};
