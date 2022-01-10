use time;

// The virtual region a moment is interpreted in
export type locality = *timezone;

// A timezone; a political region with a ruleset regarding offsets for
// calculating localized civil time
export type timezone = struct {
	// The textual identifier ("Europe/Amsterdam")
	name: str,

	// The base timescale (chrono::UTC)
	timescale: *timescale,

	// The duration of a day in this timezone (24 * time::HOUR)
	// TODO: Make this a function? Some planets may have greater rotational
	// acceleration, meaning daylength would change over time.
	daylength: time::duration,

	// The possible temporal zones a locality with this timezone can observe
	// (CET, CEST, ...)
	zones: []zone,

	// The transitions between this timezone's zones
	transitions: []transition,
};

// A timezone state, with an offset for calculating localized civil time
export type zone = struct {
	// The offset from the normal timezone (2 * time::HOUR)
	zoffset: time::duration,

	// The full descriptive name ("Central European Summer Time")
	name: str,

	// The abbreviated name ("CEST")
	abbrev: str,

	// Indicator of Daylight Saving Time
	dst: bool, // true
};

// A timezone transition between two zones
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

// Transforms and creates a new [[moment]] in a different [[locality]]
export fn in(loc: locality, m: moment) moment = {
	return new(m.date, m.time, loc); // resets .zone
};

// Returns a fictitious [[moment]] which is adjusted and normalized as if its
// locality was the normal locality. Its fields are adjusted by its current
// [[zone]]'s offset.
//
// This is a utility function for use by other modules's internal calculations.
// You probably shouldn't use this directly.
export fn localize(m: moment) moment = {
	const zone = lookupzone(&m);
	const daylen = m.loc.daylength;

	const tnew = m.time + zone.zoffset;
	const t = (if (tnew >= 0) tnew else tnew + daylen) % daylen;

	const dnew = (tnew / daylen): int;
	const d = m.date + (if (tnew >= 0) dnew else dnew - 1);

	m.time = t;
	m.date = d;
	return m;
};

// Finds and returns a [[moment]]'s currently observed zone
export fn lookupzone(m: *moment) zone = {
	if (m.zone is zone) {
		return m.zone as zone;
	};

	if (len(m.loc.zones) == 0) {
		// TODO: redesign to avoid this?
		abort("timezones should have at least one zone");
	};
	if (len(m.loc.zones) == 1) {
		const z = m.loc.zones[0];
		m.zone = z;
		return z;
	};

	// TODO: search through m.loc.trans using m.date and m.time
	if (len(m.loc.zones) > 1) {
		const z = m.loc.zones[0];
		m.zone = z;
		return z;
	};

	abort("TODO");
};

// Creates a [[timezone]] with a single [[zone]], useful for fixed offsets
//
// 	let hawaii = chrono::fixedzone(&chrono::UTC, chrono::EARTH_DAY,
// 		chrono::zone {
// 			zoffset = -10 * time::HOUR,
// 			name = "Hawaiian Reef",
// 			abbrev = "HARE",
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
	};
};

// The system's local timezone, set during initialisation
export const local: locality = &TZ_local;

// TODO: set time::chrono::local to a correct timezone
@init fn set_local_timezone() void = {
	return;
};
const TZ_local: timezone = timezone {
	name = "Local",
	timescale = &UTC,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Local Time",
			abbrev = "",
			dst = false,
		},
	],
	transitions = [],
};

// The UTC (Coordinated Universal Time) "Zulu" timezone
export const UTC_Z: locality = &TZ_UTC;

const TZ_UTC: timezone = timezone {
	name = "UTC",
	timescale = &UTC,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Universal Coordinated Time",
			abbrev = "UTC",
			dst = false,
		},
	],
	transitions = [],
};

// The TAI (International Atomic Time) "Zulu" timezone
export const TAI_Z: locality = &TZ_TAI;

const TZ_TAI: timezone = timezone {
	name = "",
	timescale = &TAI,
	daylength = EARTH_DAY,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "International Atomic Time",
			abbrev = "TAI",
			dst = false,
		},
	],
	transitions = [],
};

// The MTC (Coordinated Mars Time) "Zulu" timezone
export const MTC_Z: locality = &TZ_MTC;

const TZ_MTC: timezone = timezone {
	name = "",
	timescale = &MTC,
	daylength = MARS_SOL_MARTIAN,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Coordinated Mars Time",
			abbrev = "MTC",
			dst = false,
		},
	],
	transitions = [],
};
