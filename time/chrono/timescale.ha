// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use time;

// Represents a scale of time; a time standard.
export type timescale = struct {
	name: str,
	abbr: str,
	to_tai: *ts_converter,
	from_tai: *ts_converter,
};

// Converts one [[time::instant]] from one [[timescale]] to another.
export type ts_converter = fn(i: time::instant) (time::instant | time::error);

// International Atomic Time
//
// The realisation of proper time on Earth's geoid.
// Continuous (no leap seconds).
export const tai: timescale = timescale {
	name = "International Atomic Time",
	abbr = "TAI",
	to_tai = &conv_tai_tai,
	from_tai = &conv_tai_tai,
};

fn conv_tai_tai(i: time::instant) (time::instant | time::error) = {
	return i;
};


// TODO: Write proper conversion functions for all timescales.
//
// Ticket: https://todo.sr.ht/~sircmpwn/hare/642
//
// For UTC, conversion functions are to return two or no instants, depending on
// any leap second events, and use a proper leap second table. See leapsec.ha.


// Coordinated Universal Time
//
// Used as the basis of civil timekeeping.
// Based on TAI; time-dependent offset.
// Discontinuous (has leap seconds).
export const utc: timescale = timescale {
	name = "Coordinated Universal Time",
	abbr = "UTC",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_utc(a: time::instant) (time::instant | time::error) = {
	const idx = lookup_leaps(&utc_leapsecs, time::unix(a));
	const ofst = utc_leapsecs[idx].1;

	if (time::unix(a) == utc_leapsecs[idx].0) {
		void;
	};

	const b = time::instant {
		sec = a.sec - 37,
		nsec = a.nsec,
	};
	return b;
};

fn conv_utc_tai(a: time::instant) (time::instant | time::error) = {
	const idx = lookup_leaps(&utc_leapsecs, time::unix(a));
	const ofst = utc_leapsecs[idx].1;

	if (time::unix(a) == utc_leapsecs[idx].0) {
		void;
	};

	const b = time::instant {
		sec = a.sec + ofst,
		nsec = a.nsec,
	};
	return b;
};

fn lookup_leaps(list: *[](i64, i64), t: i64) size = {
	let lo = 0z, hi = len(list);
	for (hi - lo > 1) {
		const mid = lo + (hi - lo) / 2;
		const middle = list[mid].0;
		const cmp = time::compare(
			time::from_unix(t),
			time::from_unix(middle),
		);
		switch (cmp) {
		case -1 =>
			hi = mid;
		case 0 =>
			lo = mid; break;
		case 1 =>
			lo = mid;
		case =>
			abort("Unreachable");
		};
	};
	return lo;
};


// Global Positioning System Time
//
// Used for GPS coordination.
// Based on TAI; constant -19 second offset.
// Continuous (no leap seconds).
export const gps: timescale = timescale {
	name = "Global Positioning System Time",
	abbr = "GPS",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_gps(a: time::instant) (time::instant | time::error) = {
	const b = time::instant {
		sec = a.sec - 19,
		nsec = a.nsec,
	};
	return b;
};

fn conv_gps_tai(a: time::instant) (time::instant | time::error) = {
	const b = time::instant {
		sec = a.sec + 19,
		nsec = a.nsec,
	};
	return b;
};


// Terrestrial Time
//
// Used for astronomical timekeeping.
// Based on TAI; constant +32.184 offset.
// Continuous (no leap seconds).
export const tt: timescale = timescale {
	name = "Terrestrial Time",
	abbr = "TT",
	to_tai = &conv_tt_tai,
	from_tai = &conv_tai_tt,
};

// The constant offset between TT (Terrestrial Time) and TAI (International
// Atomic Time). Used by [[tt]].
def TT_OFFSET: time::duration = 32184 * time::MILLISECOND; // 32.184 seconds

fn conv_tai_tt(a: time::instant) (time::instant | time::error) = {
	return time::add(a, +TT_OFFSET);
};

fn conv_tt_tai(a: time::instant) (time::instant | time::error) = {
	return time::add(a, -TT_OFFSET);
};


// Arthur David Olson had expressed support for Martian time in his timezone
// database project <https://data.iana.org/time-zones/theory.html>:
//
// > The tz database does not currently support Mars time, but it is documented
// > here in the hopes that support will be added eventually.

// Coordinated Mars Time
//
// Used for timekeeping on Mars.
// Based on TT; constant factor.
// Continuous (no leap seconds).
export const mtc: timescale = timescale {
	name = "Coordinated Mars Time",
	abbr = "MTC",
	to_tai = &conv_mtc_tai,
	from_tai = &conv_tai_mtc,
};

def FACTOR_TERRESTRIAL_MARTIAN: f64 = 1.0274912517;

fn conv_tai_mtc(a: time::instant) (time::instant | time::error) = {
	// TODO: handle propagated ambiguous errors
	const b = tt.from_tai(a)?;
	const c = time::instant {
		sec = (b.sec: f64 * FACTOR_TERRESTRIAL_MARTIAN): i64,
		nsec = b.nsec,
	};
	return c;
};

fn conv_mtc_tai(a: time::instant) (time::instant | time::error) = {
	const b = time::instant {
		sec = (a.sec: f64 / FACTOR_TERRESTRIAL_MARTIAN): i64,
		nsec = a.nsec,
	};
	// TODO: handle propagated ambiguous errors
	const c = tt.to_tai(b)?;
	return c;
};
