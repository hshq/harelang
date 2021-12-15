use time;

// Represents the locality of a datetime
export type locality = (local | zoffset | *timezone | *tzalias);

// Represents its associated datetime as local
export type local = void;

// Represents a simple, constant zone offset
export type zoffset = time::duration;

// Represents a timezone; a political region with a ruleset regarding offsets
export type timezone = struct {
	name: str, // "Europe/Amsterdam"
	scale: *timescale,
	zones: []zone,
	trans: []zonetran,
};

// Represents a conditional offset, dependant on the time of year
export type zone = struct {
	zoffset: zoffset, // 2 * time::HOUR
	name: str, // "Central European Summer Time"
	abbrev: str, // "CEST"
	dst: bool, // true
};

// Represents a timezone transition
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
