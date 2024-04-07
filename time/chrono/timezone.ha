// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use os;
use path;
use sort;
use strings;
use time;

// The locality of a [[moment]]. Contains information about how to calculate a
// moment's observed chronological values.
export type locality = *timezone;

// A timezone; a political or otherwise theoretical region with a ruleset
// regarding offsets for calculating localized date/time.
export type timezone = struct {
	// The textual identifier ("Europe/Amsterdam")
	name: str,

	// The base timescale (time::chrono::utc)
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

// A [[timezone]] state, with an offset for calculating localized date/time.
export type zone = struct {
	// The offset from the normal timezone (2 * time::HOUR)
	zoff: time::duration,

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
	zoneindex: size,
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

// Frees a [[timezone]]. A [[locality]] argument can be passed.
export fn timezone_free(tz: *timezone) void = {
	free(tz.name);
	for (let zone &.. tz.zones) {
		zone_finish(zone);
	};
	free(tz.zones);
	free(tz.transitions);
	free(tz.posix_extend);
	free(tz);
};

// Frees resources associated with a [[zone]].
export fn zone_finish(z: *zone) void = {
	free(z.name);
	free(z.abbr);
};

// Creates an equivalent [[moment]] with a different [[locality]].
//
// If the moment's associated [[timescale]] and the target locality's timescale
// are different, a conversion from one to the other via the TAI timescale will
// be attempted. Any [[discontinuity]] occurrence will be returned. If a
// discontinuity against TAI amongst the two timescales exist, consider
// converting such instants manually.
export fn in(loc: locality, m: moment) (moment | discontinuity) = {
	let i = *(&m: *time::instant);
	if (m.loc.timescale != loc.timescale) {
		match (convert(i, m.loc.timescale, loc.timescale)) {
		case analytical =>
			return discontinuity;
		case let i: time::instant =>
			return new(loc, i);
		};
	};
	return new(loc, i);
};

// Finds and returns a [[moment]]'s currently observed [[zone]].
fn lookupzone(loc: locality, inst: time::instant) *zone = {
	// TODO: https://todo.sr.ht/~sircmpwn/hare/643
	if (len(loc.zones) == 0) {
		abort("time::chrono: Timezone has no zones");
	};

	if (len(loc.zones) == 1) {
		return &loc.zones[0];
	};

	let trs = loc.transitions[..];

	if (len(trs) == 0 || time::compare(inst, trs[0].when) == -1) {
		// TODO: special case
		abort("lookupzone(): time is before known transitions");
	};

	// index of transition which inst is equal to or greater than.
	const idx = -1 + sort::rbisect(
		trs, size(transition), &inst, &cmpinstants,
	);

	const z = &loc.zones[trs[idx].zoneindex];

	// if we've reached the end of the locality's transitions, try its
	// posix_extend string
	//
	// TODO: Unfinished; complete.
	if (idx == len(trs) - 1 && loc.posix_extend != "") {
		void;
	};

	return z;
};

fn cmpinstants(a: const *opaque, b: const *opaque) int = {
	let a = a: *transition;
	let b = b: *time::instant;
	return time::compare(a.when, *b): int;
};

// Creates a [[timezone]] with a single [[zone]]. Useful for fixed offsets.
// For example, replicate the civil time Hawaii timezone on Earth:
//
// 	let hawaii = chrono::fixedzone(&chrono::utc, chrono::EARTH_DAY,
// 		chrono::zone {
// 			zoff = -10 * time::HOUR,
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

// The local [[locality]]; the system or environment configured [[timezone]].
//
// This is set during the program's initialization. In order of preference, the
// TZ environment variable is used, if set; the file at [[LOCALTIME_PATH]], if
// present; or, as a last resort, [[UTC]] is used as a default.
export const LOCAL: locality = &TZ_UTC;

@init fn init_tz_local() void = {
	let path = match (os::getenv("TZ")) {
	case let path: str =>
		// remove POSIX prefix ':'
		yield if (strings::hasprefix(path, ':')) {
			yield strings::sub(path, 1, strings::end);
		} else {
			yield path;
		};
	case void =>
		yield match (os::realpath(LOCALTIME_PATH)) {
		case let path: str =>
			yield path;
		case =>
			return;
		};
	};

	match (tz(path)) {
	case => void;
	case let loc: locality =>
		LOCAL = loc;
	};
};

@fini fn free_tz_local() void = {
	if (LOCAL != UTC) {
		timezone_free(LOCAL);
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
			zoff = 0 * time::SECOND,
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
	name = "TAI",
	timescale = &tai,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoff = 0 * time::SECOND,
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
	name = "GPS",
	timescale = &gps,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoff = 0 * time::SECOND,
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
	name = "TT",
	timescale = &tt,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoff = 0 * time::SECOND,
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
	name = "MTC",
	timescale = &mtc,
	daylength = MARS_SOL_MARTIAN,
	zones = [
		zone {
			zoff = 0 * time::SECOND,
			name = "Coordinated Mars Time",
			abbr = "MTC",
			dst = false,
		},
	],
	transitions = [],
	posix_extend = "",
};
