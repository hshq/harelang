use bufio;
use endian;
use errors;
use fs;
use io;
use os;
use path;
use strings;
use time;

// Some TZif data is invalid
export type invalidtzif = !void;

// Possible errors returned from [[tz]].
export type error = !(fs::error | io::error | invalidtzif);

// Converts an [[error]] to a human-friendly representation.
export fn strerror(err: error) const str = {
	match (err) {
	case invalidtzif =>
		return "Invalid TZif data in time zone";
	case let err: fs::error =>
		return fs::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	};
};

// Parses and retrieves a [[timezone]] from the system's zoneinfo database, or
// if applicable, from an internal selection of timezones. All timezones
// provided default to the [[utc]] timescale and [[EARTH_DAY]] daylength.
export fn tz(name: str) (timezone | fs::error | io::error | invalidtzif) = {
	const filepath = path::init();
	path::add(&filepath, ZONEINFO_PREFIX, name)!;
	const fpath = path::string(&filepath);
	const file = os::open(fpath)?;
	defer io::close(file);

	static let buf: [os::BUFSIZ]u8 = [0...];
	const file = bufio::buffered(file, buf, []);
	const tz = parse_tzif(&file, timezone {
		name = name,
		timescale = &utc,
		daylength = EARTH_DAY,
		...
	})?;

	return tz;
};

// Parses data in the TZif format, and returns the given timezone with the
// fields "zones", "transitions", and "posix_extend" filled.
//
// See: https://datatracker.ietf.org/doc/html/rfc8536
fn parse_tzif(
	h: io::handle,
	tz: timezone,
) (timezone | invalidtzif | io::error) = {
	const buf1: [1]u8 = [0...];
	const buf4: [4]u8 = [0...];
	const buf8: [8]u8 = [0...];
	const buf15: [15]u8 = [0...];

	// test for magic "TZif"
	mustread(h, buf4)?;
	if (strings::fromutf8(buf4) != "TZif") {
		return invalidtzif;
	};

	// read version
	mustread(h, buf1)?;
	const version = switch (buf1[0]) {
	case 0 =>
		yield 1;
	case '2' =>
		yield 2;
	case '3' =>
		yield 3;
	case =>
		return invalidtzif;
	};

	// skip padding
	mustread(h, buf15)?;

	// read counts
	mustread(h, buf4)?; let isutcnt = endian::begetu32(buf4);
	mustread(h, buf4)?; let isstdcnt = endian::begetu32(buf4);
	mustread(h, buf4)?; let leapcnt = endian::begetu32(buf4);
	mustread(h, buf4)?; let timecnt = endian::begetu32(buf4);
	mustread(h, buf4)?; let typecnt = endian::begetu32(buf4);
	mustread(h, buf4)?; let charcnt = endian::begetu32(buf4);

	let is64 = false;
	if (version > 1) {
		is64 = true;

		// skip to the version 2 data
		const skip = (
			// size of version 1 data block
			timecnt * 4
			+ timecnt
			+ typecnt * 6
			+ charcnt
			+ leapcnt * 8
			+ isstdcnt
			+ isutcnt
			// size of version 2 header
			+ 20
		);
		for (let i = 0z; i < skip; i += 1) {
			mustread(h, buf1)?;
		};

		// read version 2 counts
		mustread(h, buf4)?; isutcnt = endian::begetu32(buf4);
		mustread(h, buf4)?; isstdcnt = endian::begetu32(buf4);
		mustread(h, buf4)?; leapcnt = endian::begetu32(buf4);
		mustread(h, buf4)?; timecnt = endian::begetu32(buf4);
		mustread(h, buf4)?; typecnt = endian::begetu32(buf4);
		mustread(h, buf4)?; charcnt = endian::begetu32(buf4);
	};

	if (typecnt == 0 || charcnt == 0) {
		return invalidtzif;
	};

	if (isutcnt != 0 && isutcnt != typecnt) {
		return invalidtzif;
	};

	if (isstdcnt != 0 && isstdcnt != typecnt) {
		return invalidtzif;
	};

	// TODO: if and how to handle? check Olson's tz code for behaviour.
	if (isutcnt != 0 && isstdcnt != 0) {
		void;
	};

	const timesz = if (is64) 8 else 4;

	// read data

	const transition_times: []i64 = [];
	if (is64) {
		readitems8(h, &transition_times, timecnt)?;
	} else {
		readitems4(h, &transition_times, timecnt)?;
	};

	const zone_indicies: []u8 = [];
	readbytes(h, &zone_indicies, timecnt)?;

	const zonedata: []u8 = [];
	readbytes(h, &zonedata, typecnt * 6)?;

	const abbrdata: []u8 = [];
	readbytes(h, &abbrdata, charcnt)?;

	const leapdata: []u8 = [];
	readbytes(h, &leapdata, leapcnt * (timesz: u32 + 4))?;

	const stdwalldata: []u8 = [];
	readbytes(h, &stdwalldata, isstdcnt)?;

	const normlocaldata: []u8 = [];
	readbytes(h, &normlocaldata, isutcnt)?;

	// read footer

	let footerdata: []u8 = [];
	mustread(h, buf1)?;
	if (buf1[0] != 0x0A) { // '\n' newline
		return invalidtzif;
	};
	for (let start = true; true; start = false) {
		mustread(h, buf1)?;
		if (buf1[0] == 0x0A) { // '\n' newline
			break;
		};
		if (buf1[0] == 0x0) { // cannot contain NUL
			return invalidtzif;
		};
		append(footerdata, buf1...);
	};
	const posix_extend = strings::fromutf8(footerdata);

	// assemble structured data

	// assemble zones
	let zones: []zone = [];
	for (let i = 0z; i < typecnt; i += 1) {
		const idx = i * 6;
		const zone = zone { ... };

		// offset
		const zoffset = endian::begetu32(zonedata[idx..idx + 4]): i32;
		if (zoffset == -2147483648) { // -2^31
			return invalidtzif;
		};
		zone.zoffset = zoffset * time::SECOND;

		// daylight saving time indicator
		zone.dst = switch (zonedata[idx + 4]) {
		case 1u8 =>
			yield true;
		case 0u8 =>
			yield false;
		case =>
			return invalidtzif;
		};

		// abbreviation
		const abbridx = zonedata[idx + 5];
		if (abbridx < 0 || abbridx > (charcnt - 1)) {
			return invalidtzif;
		};
		let bytes: []u8 = [];
		for (let j = abbridx; j < len(abbrdata); j += 1) {
			if (abbrdata[j] == 0x0) {
				bytes = abbrdata[abbridx..j];
				break;
			};
		};
		if (len(bytes) == 0) { // no NUL encountered
			return invalidtzif;
		};
		const abbr = strings::fromutf8(bytes);
		zone.abbr = abbr;

		append(zones, zone);
	};

	// assemble transitions
	let transitions: []transition = [];
	for (let i = 0z; i < timecnt; i += 1) {
		const zoneindex = zone_indicies[i]: int;
		if (zoneindex < 0 || zoneindex > (typecnt: int - 1)) {
			return invalidtzif;
		};

		const tx = transition {
			when = time::instant {
				sec = transition_times[i],
				...
			},
			zoneindex = zoneindex,
		};

		// stdwalldata and normlocaldata have been omitted,
		// until they show their utility.

		append(transitions, tx);
	};

	// commit and return data
	tz.zones = zones;
	tz.transitions = transitions;
	tz.posix_extend = posix_extend;
	return tz;
};

fn mustread(h: io::handle, buf: []u8) (void | invalidtzif | io::error) = {
	match (io::readall(h, buf)) {
	case let err: io::error =>
		return err;
	case io::EOF =>
		return invalidtzif;
	case size =>
		return;
	};
};

fn readbytes(
	h: io::handle,
	items: *[]u8,
	n: size,
) (void | invalidtzif | io::error) = {
	const buf: [1]u8 = [0];
	for (let i = 0z; i < n; i += 1) {
		mustread(h, buf)?;
		const it = buf[0];
		append(items, it);
	};
};

fn readitems8(
	h: io::handle,
	items: *[]i64,
	n: size,
) (void | invalidtzif | io::error) = {
	const buf: [8]u8 = [0...];
	for (let i = 0z; i < n; i += 1) {
		mustread(h, buf)?;
		const it = endian::begetu64(buf): i64;
		append(items, it);
	};
};

fn readitems4(
	h: io::handle,
	items: *[]i64,
	n: size,
) (void | invalidtzif | io::error) = {
	const buf: [4]u8 = [0...];
	for (let i = 0z; i < n; i += 1) {
		mustread(h, buf)?;
		const it = endian::begetu32(buf): i64;
		append(items, it);
	};
};
