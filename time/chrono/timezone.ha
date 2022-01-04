use time;

export type locality = (*timezone | *tzlink);

// The zoneinfo of a datetime
export type zoneinfo = struct {
	zabbrev: str, // %Z
	zoffset: zoffset, // %z
};

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

// An alias to a timezone
export type tzlink = struct {
	name: str,
	tz: *timezone,
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

@init set_local_timezone() void {
	// TODO
	// set time::chrono::local to a correct timezone
	return;
};

export const local: timezone = timezone {
	scale = &UTC,
	zones = [
		zone {
			zoffset = 0 * time::SECOND,
			name = "Local Time",
			abbrev = "",
			dst = false,
		},
	],
	trans = [],
	name = "",
};

export const UTC0: timezone = timezone {
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

export const TAI0: timezone = timezone {
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
