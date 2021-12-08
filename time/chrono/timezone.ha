use time;

// Represents the locality of a datetime
export type locality = (local | zoffset | timezone);

// Represents its associated datetime as local
export type local = void;

// Represents a simple, constant timezone offset
export type zoffset = time::duration;

// Represents a conditional offset, dependant on the time of year
export type zone = struct {
	zoffset: zoffset,
	applied: *fn(m: moment) bool,
	abbrev: str, // "CET"
	dst: bool,
};

// Represents a timezone; a political region with a ruleset regarding offsets
export type timezone = struct {
	timescale: timescale,
	zones: []zone,
	name: str, // "Europe/Amsterdam"
};

// Retrieves a IANA timezone object by name
export fn tzdb(name: str) timezone = {
	// TODO
	return timezone { ... };
};

//	export const TZ_UTC: timezone = timezone {
//		timescale = UTC,
//		zones = [
//			zone {
//				zoffset = 0 * time::SECOND,
//				applied = &zone_always,
//				abbrev = "UTC",
//				dst = false,
//			},
//		],
//		name = "Etc/UTC",
//	};
//	
//	fn zone_always(m: moment) bool = {
//		return true;
//	};
