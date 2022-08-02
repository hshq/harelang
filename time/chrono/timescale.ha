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
//
// During a program's initialization, this timescale initializes by loading its
// UTC/TAI leap second data from [[UTC_LEAPSECS_FILE]]; otherwise, fails
// silently. If failed, any attempt to consult UTC leapsec data (like calling
// utc.to_tai(), utc.from_tai()) causes an abort. This includes [[chrono::in]].
export const utc: timescale = timescale {
	name = "Coordinated Universal Time",
	abbr = "UTC",
	to_tai = &conv_utc_tai,
	from_tai = &conv_tai_utc,
};

fn conv_tai_utc(a: time::instant) (time::instant | time::error) = {
	if (!utc_isinitialized) {
		abort("utc timescale uninitialized");
	};

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
	if (!utc_isinitialized) {
		abort("utc timescale uninitialized");
	};

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

// The constant offset between GPS-Time (Global Positioning System Time) and TAI
// (International Atomic Time). Used by [[gps]].
def GPS_OFFSET: time::duration = -19 * time::SECOND;

fn conv_tai_gps(a: time::instant) (time::instant | time::error) = {
	return time::add(a, +GPS_OFFSET);
};

fn conv_gps_tai(a: time::instant) (time::instant | time::error) = {
	return time::add(a, -GPS_OFFSET);
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

// Factor f, where Martian-time * f == Earth-time.
def FACTOR_TERRESTRIAL_MARTIAN: f64 = 1.0274912517;

// [[time::duration]] in Earth-time between the Unix epoch of 1970 Jan 1st
// midnight, and the Earth-Mars convergence date of 2000 Jan 6th midnight.
def DELTA_UNIXEPOCH_JANSIX: time::duration = 10962 * 24 * time::HOUR;

// [[time::duration]] in Mars-time between the Mars Sol Date epoch corresponding
// to the Gregorian Earth date 1873 Dec 29th, and the Earth-Mars convergence
// date of 2000 Jan 6.
def DELTA_MARSEPOCH_JANSIX: time::duration = 44796 * 24 * time::HOUR;

// [[time::duration]] in Mars-time between the midnights of 2000 Jan 6th on
// Earth and Mars. Earth's midnight occurred first.
def DELTA_JANSIX_ADJUSTMENT: time::duration = 82944 * time::MILLISECOND;

fn conv_tai_mtc(a: time::instant) (time::instant | time::error) = {
	// Get the "Terrestrial Time".
	// '!' since TT and TAI are continuous.
	const b = tt.from_tai(a)!;

	// Change epoch from the Unix epoch 1970 Jan 1st (Terrestrial Time)
	// to the Earth-Mars convergence date 2000 Jan 6th midnight.
	const b = time::add(b, -DELTA_UNIXEPOCH_JANSIX);

	// Scale from Earth-time to Mars-time.
	const b = time::mult(b, 1.0 / FACTOR_TERRESTRIAL_MARTIAN);

	// Slightly adjust epoch for the actual Martian midnight.
	// Earth's midnight occurred before Mars'.
	const b = time::add(b, -DELTA_JANSIX_ADJUSTMENT);

	// Change epoch to that of the Mars Sol Date.
	const b = time::add(b, +DELTA_MARSEPOCH_JANSIX);

	return b;
};

fn conv_mtc_tai(a: time::instant) (time::instant | time::error) = {
	// Change epoch from that of the Mars Sol Date
	// to the Earth-Mars convergence date 2000 Jan 6th.
	const b = time::add(a, -DELTA_MARSEPOCH_JANSIX);

	// Slightly adjust epoch for the actual Martian midnight.
	// Earth's midnight occurred before Mars'.
	const b = time::add(b, +DELTA_JANSIX_ADJUSTMENT);

	// Scale from Mars-time to Earth-time.
	const b = time::mult(b, FACTOR_TERRESTRIAL_MARTIAN);

	// Change epoch to the Unix epoch 1970 Jan 1st (Terrestrial Time).
	const b = time::add(b, +DELTA_UNIXEPOCH_JANSIX);

	// Get the TAI time.
	// '!' since TT and TAI are continuous.
	const b = tt.to_tai(b)!;

	return b;
};
