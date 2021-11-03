use time;

// Represents the locality of a datetime
export type locality = (local | zoffset | *timezone);

// Represents its associated datetime as local
export type local = void;

// Represents a simple, constant zone offset
export type zoffset = time::duration;

// Represents a conditional offset, dependant on the time of year
export type zone = struct {
	zoffset: zoffset, // 2 * time::HOUR
	name: str, // "Central European Summer Time"
	abbrev: str, // "CEST"
	dst: bool, // true
};

// Represents a timezone; a political region with a ruleset regarding offsets
export type timezone = struct {
	aliasof: (void | *timezone),
	scale: *timescale,
	zones: []zone,
	applied: *fn(m: moment) uint,
	name: str, // "Europe/Amsterdam"
};

export const TZ_UTC: timezone = timezone {
	aliasof = void,
	scale = &UTC,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Universal Coordinated Time",
			abbrev = "UTC",
			dst = false,
		},
	],
	applied = &zone_const,
	name = "Etc/UTC",
};

export const TZ_TAI: timezone = timezone {
	aliasof = void,
	scale = &TAI,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "International Atomic Time",
			abbrev = "TAI",
			dst = false,
		},
	],
	applied = &zone_const,
	name = "",
};

fn zone_const(m: moment) uint = {
	return 0u;
};
