use time;

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

// Returns a fictitious moment which assumes it's own locality is the normal
// locality. The given timezone is consulted to find the current zone, and its
// offset is applied to the new .date and .time fields.
export fn localize(m: moment) moment = {
	const zone = lookupzone(m);
	const newtime = m.time + zone.zoffset;
	m.time = newtime % m.loc.daylength;
	m.date += (newtime / m.loc.daylength);
	return m;
};

export fn lookupzone(m: moment) zone = {
	// TODO: search through m.loc.trans using m.date and m.time
	return zone{ ... };
};

// The system's local timezone, set during initialisation
export const local: *timezone = &TZ_local;

// TODO: set time::chrono::local to a correct timezone
@init fn set_local_timezone() void = {
	return;
};
const TZ_local: timezone = timezone {
	name = "",
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

// The UTC "Zulu" timezone
export const UTC_Z: *timezone = &TZ_UTC;

const TZ_UTC: timezone = timezone {
	name = "Etc/UTC",
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

// The TAI "Zulu" timezone
export const TAI_Z: *timezone = &TZ_TAI;

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
