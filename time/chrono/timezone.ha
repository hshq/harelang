use time;

// The locality of a datetime
export type locality = struct {
	zrepr: str, // %Z
	zoffset: zoffset, // %z
	timezone: (*timezone | local),
};

// A destructured dual std/dst POSIX timezone. See tzset(3).
type tzname = struct {
	std_name: str,
	std_offset: zoffset,
	dst_name: str,
	dst_offset: zoffset,
	dst_start: str,
	dst_starttime: str,
	dst_end: str,
	dst_endtime: str,
};

// Represents its associated datetime as local
export type local = void;

// A simple, constant zone offset
export type zoffset = time::duration;

// A timezone; a political region with a ruleset regarding offsets
export type timezone = struct {
	name: str, // "Europe/Amsterdam"
	scale: *timescale,
	zones: []zone,
	trans: []zonetran,
};

// A conditional offset, dependant on the time of year
export type zone = struct {
	zoffset: zoffset, // 2 * time::HOUR
	name: str, // "Central European Summer Time"
	abbrev: str, // "CEST"
	dst: bool, // true
};

// A timezone transition
export type zonetran = struct {
	when: time::instant,
	zoneindex: int,
};

export type tzalias = struct {
	name: str,
	tz: *timezone,
};

export const TZ_UTC: timezone = timezone {
	scale = &UTC,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Universal Coordinated Time",
			abbrev = "UTC",
			dst = false,
		},
	],
	trans = [],
	name = "Etc/UTC",
};

export const TZ_TAI: timezone = timezone {
	scale = &TAI,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "International Atomic Time",
			abbrev = "TAI",
			dst = false,
		},
	],
	trans = [],
	name = "",
};
