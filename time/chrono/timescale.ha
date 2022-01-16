use time;

// Represents a scale of time; a time standard
export type timescale = struct {
	name: str,
	abbrev: str,
	to_tai: *ts_converter,
	from_tai: *ts_converter,
};

// Converts one [[time::instant]] in one [[chrono::timescale]] to another
export type ts_converter = fn(i: time::instant) (time::instant | time::error);

// International Atomic Time
//
// The realisation of proper time on Earth's geoid.
// Continuous (no leap seconds).
export const TAI: timescale = timescale {
	name = "International Atomic Time",
	abbrev = "TAI",
	to_tai = &conv_tai_tai,
	from_tai = &conv_tai_tai,
};

fn conv_tai_tai(i: time::instant) (time::instant | time::error) = {
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
	name = "Coordinated Universal Time",
	abbrev = "UTC",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_utc(tai: time::instant) (time::instant | time::error) = {
	const utc = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return utc;
};

fn conv_utc_tai(utc: time::instant) (time::instant | time::error) = {
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
	name = "Unix Time",
	abbrev = "UNIX",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_unix(tai: time::instant) (time::instant | time::error) = {
	const unix = time::instant {
		sec = tai.sec - 37,
		nsec = tai.nsec,
	};
	return unix;
};

fn conv_unix_tai(unix: time::instant) (time::instant | time::error) = {
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
	name = "Global Positioning System Time",
	abbrev = "GPS",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_gps(tai: time::instant) (time::instant | time::error) = {
	const gps = time::instant {
		sec = tai.sec - 19,
		nsec = tai.nsec,
	};
	return gps;
};

fn conv_gps_tai(gps: time::instant) (time::instant | time::error) = {
	const tai = time::instant {
		sec = gps.sec + 19,
		nsec = gps.nsec,
	};
	return tai;
};


// Terrestrial Time
//
// Used for astronomical timekeeping.
// Based on TAI, with a constant offset.
// Continuous (no leap seconds).
export const TT: timescale = timescale {
	name = "Terrestrial Time",
	abbrev = "TT",
	to_tai = &conv_tt_tai,
	from_tai = &conv_tai_tt,
};

def TT_OFFSET: time::duration = 32.184 * time::SECOND;

fn conv_tai_tt(tai: time::instant) (time::instant | time::error) = {
	const tt = time::instant {
		sec = tai.sec + (TT_OFFSET / time::SECOND),
		nsec = tai.nsec + (TT_OFFSET % time::SECOND),
	};
	return tt;
};

fn conv_tt_tai(tt: time::instant) (time::instant | time::error) = {
	const tai = time::instant {
		sec = tt.sec - (TT_OFFSET / time::SECOND),
		nsec = tt.nsec + (TT_OFFSET % time::SECOND),
	};
	return tai;
};


// Coordinated Mars Time
//
// Used for local solar time on Mars.
// Based on TT, with a constant factor.
// Continuous (no leap seconds).
export const MTC: timescale = timescale {
	name = "Coordinated Mars Time",
	abbrev = "MTC",
	to_tai = &conv_mtc_tai,
	from_tai = &conv_tai_mtc,
};

def FACTOR_TERRESTRIAL_MARTIAN: f64 = 1.0274912517;

fn conv_tai_mtc(tai: time::instant) (time::instant | time::error) = {
	// TODO: handle propagated ambiguous errors
	const tt = TT.from_tai(tai)?;
	const mtc = time::instant {
		sec = (tt.sec: f64 * FACTOR_TERRESTRIAL_MARTIAN): i64,
		nsec = tt.nsec,
	};
	return mtc;
};

fn conv_mtc_tai(mtc: time::instant) (time::instant | time::error) = {
	const tt = time::instant {
		sec = (mtc.sec: f64 / FACTOR_TERRESTRIAL_MARTIAN): i64,
		nsec = mtc.nsec,
	};
	// TODO: handle propagated ambiguous errors
	const tai = TT.to_tai(tt)?;
	return tai;
};
