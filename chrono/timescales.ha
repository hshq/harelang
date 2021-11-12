use time;

// Represents a linear scale of time, with an epoch.
export type timescale = struct {
	to_tai: *converter,
	from_tai: *converter,
};

export type converter = fn(i: time::instant) []time::instant;


// International Atomic Time
//
// The realisation of proper time on Earth's geoid.
// Continuous (no leap seconds).
export const TAI: timescale = timescale {
	to_tai = &conv_tai_tai,
	from_tai = &conv_tai_tai,
};

fn conv_tai_tai(i: time::instant) []time::instant = {
	return [i];
};


// TODO: Write proper conversion functions for all timescales.
// Functions are to return two or no instants, depending on any leap second
// events, and use a proper leap second table.
// https://www.ietf.org/timezones/data/leap-seconds.list


// Coordinated Universal Time
//
// Based on TAI. Used as the basis of civil timekeeping.
// Discontinuous (has leap seconds).
export const UTC: timescale = timescale {
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_utc(tai: time::instant) []time::instant = {
	const utc = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return [utc];
};

fn conv_utc_tai(utc: time::instant) []time::instant = {
	const tai = time::instant {
		sec = utc.sec + 37,
		nsec = utc.nsec,
	};
	return [tai];
};


// Unix Time
//
// Based on UTC. Used for computer timekeeping.
// Discontinuous (has leap seconds).
export const UNIX: timescale = timescale {
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_unix(tai: time::instant) []time::instant = {
	const unix = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return [unix];
};

fn conv_unix_tai(unix: time::instant) []time::instant = {
	const tai = time::instant {
		sec = unix.sec + 37,
		nsec = unix.nsec,
	};
	return [tai];
};

