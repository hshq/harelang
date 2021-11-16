use time;

// Represents a linear scale of time, with an epoch.
export type timescale = struct {
	to_tai: *ts_converter,
	from_tai: *ts_converter,
};

// Converts one [[time::instant]] in one [[chrono::timescale]] to another
export type ts_converter = fn(i: time::instant) (time::instant | ambiguous | nonexistent);

// All error type which can be returned from chronological functions
export type error = !(ambiguous | nonexistent);

// Represents multiple possible corresponding [[time::instant]]s attained by a
// timescale conversion
export type ambiguous = ![]time::instant;

// Represents the absence of a corresponding [[time::instant]] following a
// timescale conversion
export type nonexistent = !void;


// International Atomic Time
//
// The realisation of proper time on Earth's geoid.
// Continuous (no leap seconds).
export const TAI: timescale = timescale {
	to_tai = &conv_tai_tai,
	from_tai = &conv_tai_tai,
};

fn conv_tai_tai(i: time::instant) (time::instant | ambiguous | nonexistent) = {
	return i;
};


// TODO: Write proper conversion functions for all timescales.
// Functions are to return two or no instants, depending on any leap second
// events, and use a proper leap second table.
// https://www.ietf.org/timezones/data/leap-seconds.list


// Coordinated Universal Time
//
// Used as the basis of civil timekeeping.
// Based on TAI, with an offset, changed roughly biannually.
// Discontinuous (has leap seconds).
export const UTC: timescale = timescale {
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_utc(tai: time::instant) (time::instant | ambiguous | nonexistent) = {
	const utc = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return utc;
};

fn conv_utc_tai(utc: time::instant) (time::instant | ambiguous | nonexistent) = {
	const tai = time::instant {
		sec = utc.sec + 37,
		nsec = utc.nsec,
	};
	return tai;
};


// Unix Time
//
// Used for computer timekeeping.
// Based on UTC, near 1-to-1 correspondence.
// Discontinuous (has leap seconds).
export const UNIX: timescale = timescale {
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_unix(tai: time::instant) (time::instant | ambiguous | nonexistent) = {
	const unix = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return unix;
};

fn conv_unix_tai(unix: time::instant) (time::instant | ambiguous | nonexistent) = {
	const tai = time::instant {
		sec = unix.sec + 37,
		nsec = unix.nsec,
	};
	return tai;
};



// Global Positioning System Time
//
// Used for GPS coordination.
// Based on TAI, constant -19 second offset.
// Continuous (no leap seconds).
export const GPS: timescale = timescale {
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_gps(tai: time::instant) (time::instant | ambiguous | nonexistent) = {
	const gps = time::instant {
		sec = tai.sec - 19,
		nsec = tai.nsec,
	};
	return gps;
};

fn conv_gps_tai(gps: time::instant) (time::instant | ambiguous | nonexistent) = {
	const tai = time::instant {
		sec = gps.sec + 19,
		nsec = gps.nsec,
	};
	return tai;
};

