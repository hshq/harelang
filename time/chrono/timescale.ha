// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use time;

// Represents a scale of time; a time standard. See [[convert]].
export type timescale = struct {
	name: str,
	abbr: str,
	convto: *tsconverter,
	convfrom: *tsconverter,
};

export type tsconverter = fn(ts: *timescale, i: time::instant) ([]time::instant | void);

// A discontinuity between two [[timescale]]s caused a one-to-one
// [[time::instant]] conversion to fail.
export type discontinuity = !void;

// The analytical result of a [[time::instant]] conversion between two
// [[timescale]]s at a point of [[discontinuity]].
//
// An empty slice represents a nonexistent conversion result.
// A populated (>1) slice represents an ambiguous conversion result.
export type analytical = ![]time::instant;

// Converts a [[time::instant]] from one [[timescale]] to the next exhaustively.
// The final conversion result is returned. For each active pair of timescales,
// if neither implements conversion from the first to the second, a two-step
// intermediary TAI conversion will occur. If given zero or one timescales, the
// given instant is returned.
export fn convert(i: time::instant, tscs: *timescale...) (time::instant | analytical) = {
	let ts: []time::instant = [i];
	let tmps: []time::instant = [];

	for (let j = 1z; j < len(tscs); j += 1) {
		let a = tscs[j - 1];
		let b = tscs[j];

		for (let k = 0z; k < len(ts); k += 1) {
			const t = ts[k];

			// try .convto
			match (a.convto(b, t)) {
			case let convs: []time::instant =>
				append(tmps, convs...);
				continue;
			case void => void;
			};

			// try .convfrom
			match (b.convfrom(a, t)) {
			case let convs: []time::instant =>
				append(tmps, convs...);
				continue;
			case void => void;
			};

			// default to TAI intermediary
			const convs = a.convto(&tai, t) as []time::instant;
			for (let l = 0z; l < len(convs); l += 1) {
				append(tmps, (
					b.convfrom(&tai, convs[l]) as []time::instant
				)...);
			};
		};

		// TODO: sort and deduplicate 'ts' here
		ts = tmps;
		tmps = [];
	};

	return if (len(ts) == 1) ts[0] else ts;
};


// International Atomic Time
//
// The realisation of proper time on Earth's geoid.
// Continuous (no leap seconds).
export const tai: timescale = timescale {
	name = "International Atomic Time",
	abbr = "TAI",
	convto = &tai_convto,
	convfrom = &tai_convfrom,
};

fn tai_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &tai =>
		return [i];
	case =>
		return void;
	};
};


fn tai_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &tai =>
		return [i];
	case =>
		return void;
	};
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
// silently. If failed, any attempt to consult UTC leapsec data (e.g. calling
// [[convert]] on UTC) causes an abort. This includes [[in]].
export const utc: timescale = timescale {
	name = "Coordinated Universal Time",
	abbr = "UTC",
	convto = &utc_convto,
	convfrom = &utc_convfrom,
};

fn utc_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &utc =>
		return [i];
	case &tai =>
		if (!utc_isinitialized) {
			match (init_utc_leapsecs()) {
			case void =>
				utc_isinitialized = true;
			case =>
				abort("utc timescale uninitialized");
			};
		};

		const idx = lookup_leaps(&utc_leapsecs, time::unix(i));
		const ofst = utc_leapsecs[idx].1;

		if (time::unix(i) == utc_leapsecs[idx].0) {
			void;
		};

		const i = time::instant {
			sec = i.sec + 37,
			nsec = i.nsec,
		};

		return [i];
	case =>
		return void;
	};
};

fn utc_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &utc =>
		return [i];
	case &tai =>
		if (!utc_isinitialized) {
			match (init_utc_leapsecs()) {
			case void =>
				utc_isinitialized = true;
			case =>
				abort("utc timescale uninitialized");
			};
		};

		const idx = lookup_leaps(&utc_leapsecs, time::unix(i));
		const ofst = utc_leapsecs[idx].1;

		if (time::unix(i) == utc_leapsecs[idx].0) {
			void;
		};

		const i = time::instant {
			sec = i.sec - 37,
			nsec = i.nsec,
		};

		return [i];
	case =>
		return void;
	};
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
	convto = &gps_convto,
	convfrom = &gps_convfrom,
};

// The constant offset between GPS-Time (Global Positioning System Time) and TAI
// (International Atomic Time). Used by [[gps]].
def GPS_OFFSET: time::duration = -19 * time::SECOND;

fn gps_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &gps =>
		return [i];
	case &tai =>
		return [time::add(i, -GPS_OFFSET)];
	case =>
		void;
	};
};

fn gps_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &gps =>
		return [i];
	case &tai =>
		return [time::add(i, +GPS_OFFSET)];
	case =>
		void;
	};
};


// Terrestrial Time
//
// Used for astronomical timekeeping.
// Based on TAI; constant +32.184 offset.
// Continuous (no leap seconds).
export const tt: timescale = timescale {
	name = "Terrestrial Time",
	abbr = "TT",
	convto = &tt_convto,
	convfrom = &tt_convfrom,
};

// The constant offset between TT (Terrestrial Time) and TAI (International
// Atomic Time). Used by [[tt]].
def TT_OFFSET: time::duration = 32184 * time::MILLISECOND; // 32.184 seconds

fn tt_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &tt =>
		return [i];
	case &tai =>
		return [time::add(i, -TT_OFFSET)];
	case =>
		void;
	};
};


fn tt_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &tt =>
		return [i];
	case &tai =>
		return [time::add(i, +TT_OFFSET)];
	case =>
		void;
	};
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
	convto = &mtc_convto,
	convfrom = &mtc_convfrom,
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

fn mtc_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &mtc =>
		return [i];
	case &tai =>
		// Change epoch from that of the Mars Sol Date
		// to the Earth-Mars convergence date 2000 Jan 6th.
		let i = time::add(i, -DELTA_MARSEPOCH_JANSIX);

		// Slightly adjust epoch for the actual Martian midnight.
		// Earth's midnight occurred before Mars'.
		i = time::add(i, +DELTA_JANSIX_ADJUSTMENT);

		// Scale from Mars-time to Earth-time.
		i = time::mult(i, FACTOR_TERRESTRIAL_MARTIAN);

		// Change epoch to the Unix epoch 1970 Jan 1st (Terrestrial Time).
		i = time::add(i, +DELTA_UNIXEPOCH_JANSIX);

		// Get the TAI time.
		// assertion since TT and TAI are continuous.
		const ts = tt.convto(&tai, i) as []time::instant;

		return ts;
	case =>
		void;
	};

};

fn mtc_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	switch (ts) {
	case &mtc =>
		return [i];
	case &tai =>
		// Get the "Terrestrial Time".
		// assertion since TT and TAI are continuous.
		let i = (tt.convfrom(&tai, i) as []time::instant)[0];

		// Change epoch from the Unix epoch 1970 Jan 1st (Terrestrial Time)
		// to the Earth-Mars convergence date 2000 Jan 6th midnight.
		i = time::add(i, -DELTA_UNIXEPOCH_JANSIX);

		// Scale from Earth-time to Mars-time.
		i = time::mult(i, 1.0 / FACTOR_TERRESTRIAL_MARTIAN);

		// Slightly adjust epoch for the actual Martian midnight.
		// Earth's midnight occurred before Mars'.
		i = time::add(i, -DELTA_JANSIX_ADJUSTMENT);

		// Change epoch to that of the Mars Sol Date.
		i = time::add(i, +DELTA_MARSEPOCH_JANSIX);

		return [i];
	case =>
		void;
	};

};
