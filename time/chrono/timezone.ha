// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use bufio;
use io;
use os;
use path;
use strings;
use time;

// The locality of a [[moment]]. Contains information about how to present a
// moment's chronological values.
export type locality = *timezone;

// A timezone; a political or general region with a ruleset regarding offsets
// for calculating localized civil time.
export type timezone = struct {
	// The textual identifier ("Europe/Amsterdam")
	name: str,

	// The base timescale (chrono::utc)
	timescale: *timescale,

	// The duration of a day in this timezone (24 * time::HOUR)
	daylength: time::duration,

	// The possible temporal zones a locality with this timezone can observe
	// (CET, CEST, ...)
	zones: []zone,

	// The transitions between this timezone's zones
	transitions: []transition,

	// A timezone specifier in the POSIX "expanded" TZ format.
	// See https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html
	//
	// Used for extending calculations beyond the last known transition.
	posix_extend: str,
};

// A [[timezone]] state, with an offset for calculating localized civil time.
export type zone = struct {
	// The offset from the normal timezone (2 * time::HOUR)
	zoffset: time::duration,

	// The full descriptive name ("Central European Summer Time")
	name: str,

	// The abbreviated name ("CEST")
	abbr: str,

	// Indicator of Daylight Saving Time
	dst: bool, // true
};

// A [[timezone]] transition between two [[zone]]s.
export type transition = struct {
	when: time::instant,
	zoneindex: int,
};

// A destructured dual std/dst POSIX timezone. See tzset(3).
type tzname = struct {
	std_name: str,
	std_offset: time::duration,
	dst_name: str,
	dst_offset: time::duration,
	dst_start: str,
	dst_starttime: str,
	dst_end: str,
	dst_endtime: str,
};

// Creates an equivalent [[moment]] with a different [[locality]].
//
// If the old and new localities have different timescales, a direct conversion
// between them will be tried, and will abort if unsuccessful. To avoid this,
// consider manually converting moments to instants, and those instants between
// timescales.
export fn in(loc: locality, m: moment) moment = {
	if (m.loc.timescale != loc.timescale) {
		const i = to_instant(m);
		const i = match (m.loc.timescale.to_tai(i)) {
		case let i: time::instant =>
			yield i;
		case time::error =>
			abort("time::chrono::in(): direct timescale conversion failed");
		};
		const i = match (loc.timescale.from_tai(i)) {
		case let i: time::instant =>
			yield i;
		case time::error =>
			abort("time::chrono::in(): direct timescale conversion failed");
		};
		const m = from_instant(i, loc);
		return m;
	};

	assert(m.time < loc.daylength, "Internal error: time excedes daylength");
	return new(loc, m.date, m.time)!; // resets .zone
};

export fn transform(m: moment, zo: time::duration) moment = {
	const daylen = m.loc.daylength;

	const t = m.time + zo;
	const mtime = (if (t >= 0) t else t + daylen) % daylen;

	const d = (t / daylen): int;
	const mdate = m.date + (if (t >= 0) d else d - 1);

	m.time = mtime;
	m.date = mdate;
	return m;
};

// Finds, sets and returns a [[moment]]'s currently observed zone.
export fn lookupzone(m: *moment) zone = {
	// TODO: https://todo.sr.ht/~sircmpwn/hare/643
	if (len(m.loc.zones) == 0) {
		// TODO: what to do? not ideal to assume UTC
		abort("lookup(): timezones should have at least one zone");
	};

	if (len(m.loc.zones) == 1) {
		m.zone = m.loc.zones[0];
		return m.zone;
	};

	const inst = to_instant(*m);

	if (
		len(m.loc.transitions) == 0
		|| time::compare(inst, m.loc.transitions[0].when) == -1
	) {
		// TODO: special case
		abort("lookupzone(): time is before known transitions");
	};

	let lo = 0z;
	let hi = len(m.loc.transitions);
	for (hi - lo > 1) {
		const mid = lo + (hi - lo) / 2;
		const middle = m.loc.transitions[mid].when;
		switch (time::compare(inst, middle)) {
		case -1 =>
			hi = mid;
		case 0 =>
			lo = mid; break;
		case 1 =>
			lo = mid;
		case =>
			abort("Unreachable");
		};
	};

	m.zone = m.loc.zones[m.loc.transitions[lo].zoneindex];

	// if we've reached the end of the locality's transitions, try its
	// posix_extend string
	//
	// TODO: Unfinished; complete.
	if (lo == len(m.loc.transitions) - 1 && m.loc.posix_extend != "") {
		void;
	};

	return m.zone;
};

// Creates a [[timezone]] with a single [[zone]]. Useful for fixed offsets.
// For example, replicate the civil time Hawaii timezone on Earth:
//
// 	let hawaii = chrono::fixedzone(&chrono::utc, chrono::EARTH_DAY,
// 		chrono::zone {
// 			zoffset = -10 * time::HOUR,
// 			name = "Hawaiian Reef",
// 			abbr = "HARE",
// 			dst = false,
// 		},
// 	);
//
export fn fixedzone(ts: *timescale, daylen: time::duration, z: zone) timezone = {
	return timezone {
		name = z.name,
		timescale = ts,
		daylength = daylen,
		zones = alloc([z]),
		transitions = [],
		posix_extend = "",
	};
};

// The system's [[locality]]; the system's local [[timezone]].
//
// This is set during a program's initialisation, where the TZ environment
// variable is tried, otherwise the /etc/localtime file is tried, otherwise a
// default is used.
//
// The default timezone is equivalent to that of [[UTC]], with "Local" being the
// name of both the timezone and its single zero-offset zone.
export const LOCAL: locality = &TZ_LOCAL;

let TZ_LOCAL: timezone = timezone {
	name = "Local",
	timescale = &utc,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Local",
			abbr = "",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};

@fini fn free_tzdata() void = {
	free(TZ_LOCAL.transitions);
	free(TZ_LOCAL.zones);
};

@init fn set_local_timezone() void = {
	match (os::getenv("TZ")) {
	case let zone: str =>
		TZ_LOCAL = match (tz(zone)) {
		case let tz: timezone =>
			yield tz;
		case =>
			return;
		};
	case void =>
		const filepath = match (os::readlink(LOCALTIME_PATH)) {
		case let fp: str =>
			yield fp;
		case =>
			yield LOCALTIME_PATH;
		};

		const file = match (os::open(filepath)) {
		case let f: io::file =>
			yield f;
		case =>
			return;
		};
		defer io::close(file)!;

		if (strings::hasprefix(filepath, ZONEINFO_PREFIX)) {
			TZ_LOCAL.name = strings::trimprefix(
				filepath, ZONEINFO_PREFIX,
			);
		};

		static let buf: [os::BUFSIZ]u8 = [0...];
		const file = bufio::buffered(file, buf, []);
		match (parse_tzif(&file, &TZ_LOCAL)) { case => void; };
	};
};

// The UTC (Coordinated Universal Time) "Zulu" [[timezone]] as a [[locality]].
export const UTC: locality = &TZ_UTC;

const TZ_UTC: timezone = timezone {
	name = "UTC",
	timescale = &utc,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Universal Coordinated Time",
			abbr = "UTC",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};

// The TAI (International Atomic Time) "Zulu" [[timezone]] as a [[locality]].
export const TAI: locality = &TZ_TAI;

const TZ_TAI: timezone = timezone {
	name = "",
	timescale = &tai,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "International Atomic Time",
			abbr = "TAI",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};

// The GPS (Global Positioning System) "Zulu" [[timezone]] as a [[locality]].
export const GPS: locality = &TZ_GPS;

const TZ_GPS: timezone = timezone {
	name = "",
	timescale = &gps,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Global Positioning System",
			abbr = "GPS",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};

// The TT (Terrestrial Time) "Zulu" [[timezone]] as a [[locality]].
export const TT: locality = &TZ_TT;

const TZ_TT: timezone = timezone {
	name = "",
	timescale = &tt,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Terrestrial Time",
			abbr = "TT",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};

// The MTC (Coordinated Mars Time) "Zulu" [[timezone]] as a [[locality]].
export const MTC: locality = &TZ_MTC;

const TZ_MTC: timezone = timezone {
	name = "",
	timescale = &mtc,
	daylength = MARS_SOL_MARTIAN,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Coordinated Mars Time",
			abbr = "MTC",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};
