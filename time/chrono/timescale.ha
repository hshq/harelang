// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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

			for (let conv .. convs) {
				append(tmps, (
					b.convfrom(&tai, conv) as []time::instant
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
	convto = &tai_conv,
	convfrom = &tai_conv,
};

fn tai_conv(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &tai =>
		append(ret, i);
		return ret;
	case =>
		return void;
	};
};


// Coordinated Universal Time
//
// Used as the basis of civil timekeeping.
// Based on TAI; time-dependent offset.
// Discontinuous (has leap seconds).
//
// During a program's initialization, this timescale initializes by loading its
// UTC/TAI leap second data from [[UTC_LEAPSECS_PATH]]; otherwise, fails
// silently. If failed, any attempt to consult UTC leapsec data (e.g. calling
// [[convert]] on UTC) causes an abort. This includes [[in]].
export const utc: timescale = timescale {
	name = "Coordinated Universal Time",
	abbr = "UTC",
	convto = &utc_convto,
	convfrom = &utc_convfrom,
};

fn utc_convto(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &utc =>
		append(ret, i);
		return ret;
	case &tai =>
		if (!utc_isinitialized) {
			match (init_utc_leapsecs()) {
			case void =>
				utc_isinitialized = true;
			case =>
				abort("Failed to initialize UTC timescale");
			};
		};

		const firstleap = utc_leapsecs[0]; // TODO: no leapsecs loaded
		if (time::compare(i, time::from_unix(firstleap.0)) < 0) {
			append(ret, time::instant {
				sec = i.sec + firstleap.1,
				nsec = i.nsec,
			});
			return ret;
		};

		for (let idx = len(utc_leapsecs) - 1; idx >= 0 ; idx -= 1) {
			const leap = utc_leapsecs[idx];
			const leapsecond = time::from_unix(leap.0);
			const leapoffset = leap.1;
			const diff = time::diff(leapsecond, i);

			const prevleapoffset =
				if (idx == 0) 0i64 else utc_leapsecs[idx - 1].1;
			const offsetdiff =
				(leapoffset - prevleapoffset) * time::SECOND;

			// case of positive leap second (UTC repeats a second)
			if (offsetdiff >= 0) {
				if (diff >= 0) {
					append(ret, time::instant {
						sec = i.sec + leapoffset,
						nsec = i.nsec,
					});
					return ret;
				};

				if (diff >= -offsetdiff && diff < 0) {
					append(ret, [
						time::instant {
							sec = i.sec + prevleapoffset,
							nsec = i.nsec,
						},
						time::instant {
							sec = i.sec + leapoffset,
							nsec = i.nsec,
						},
					]...);
					return ret;
				};

				continue;
			};

			// case of negative leap second (UTC skips a second)
			if (offsetdiff < 0) {
				if (diff >= 0) {
					append(ret, time::instant {
						sec = i.sec + leapoffset,
						nsec = i.nsec,
					});
					return ret;
				};

				if (diff >= offsetdiff && diff < 0) {
					return ret;
				};

				continue;
			};
		};
	case =>
		return void;
	};
};

fn utc_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &utc =>
		append(ret, i);
		return ret;
	case &tai =>
		if (!utc_isinitialized) {
			match (init_utc_leapsecs()) {
			case void =>
				utc_isinitialized = true;
			case =>
				abort("Failed to initialize UTC timescale");
			};
		};

		const firstleap = utc_leapsecs[0]; // TODO: no leapsecs loaded
		if (time::compare(i, time::from_unix(firstleap.0 + firstleap.1)) < 0) {
			append(ret, time::instant {
				sec = i.sec - firstleap.1,
				nsec = i.nsec,
			});
			return ret;
		};

		for (let idx = len(utc_leapsecs) - 1; idx >= 0 ; idx -= 1) {
			const leap = utc_leapsecs[idx];
			const leapsecond = time::from_unix(leap.0 + leap.1);
			const leapoffset = leap.1;
			const diff = time::diff(leapsecond, i);

			const prevleapoffset =
				if (idx == 0) 10i64 else utc_leapsecs[idx - 1].1;
			const offsetdiff
				= (leapoffset - prevleapoffset) * time::SECOND;

			// case of positive leap second (UTC repeats a second)
			if (offsetdiff >= 0) {
				if (diff >= -offsetdiff) {
					append(ret, time::instant {
						sec = i.sec - leapoffset,
						nsec = i.nsec,
					});
					return ret;
				};

				continue;
			};

			// case of negative leap second (UTC skips a second)
			if (offsetdiff < 0) {
				if (diff >= 0) {
					append(ret, time::instant {
						sec = i.sec - leapoffset,
						nsec = i.nsec,
					});
					return ret;
				};

				continue;
			};
		};
	case =>
		return void;
	};
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
	let ret: []time::instant = [];
	switch (ts) {
	case &gps =>
		append(ret, i);
		return ret;
	case &tai =>
		append(ret, time::add(i, -GPS_OFFSET));
		return ret;
	case =>
		return void;
	};
};

fn gps_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &gps =>
		append(ret, i);
		return ret;
	case &tai =>
		append(ret, time::add(i, GPS_OFFSET));
		return ret;
	case =>
		return void;
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
	let ret: []time::instant = [];
	switch (ts) {
	case &tt =>
		append(ret, i);
		return ret;
	case &tai =>
		append(ret, time::add(i, -TT_OFFSET));
		return ret;
	case =>
		return void;
	};
};


fn tt_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &tt =>
		append(ret, i);
		return ret;
	case &tai =>
		append(ret, time::add(i, TT_OFFSET));
		return ret;
	case =>
		return void;
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
	let ret: []time::instant = [];
	switch (ts) {
	case &mtc =>
		append(ret, i);
		return ret;
	case &tai =>
		// Change epoch from that of the Mars Sol Date
		// to the Earth-Mars convergence date 2000 Jan 6th.
		let i = time::add(i, -DELTA_MARSEPOCH_JANSIX);

		// Slightly adjust epoch for the actual Martian midnight.
		// Earth's midnight occurred before Mars'.
		i = time::add(i, DELTA_JANSIX_ADJUSTMENT);

		// Scale from Mars-time to Earth-time.
		i = time::mult(i, FACTOR_TERRESTRIAL_MARTIAN);

		// Change epoch to the Unix epoch 1970 Jan 1st (Terrestrial Time).
		i = time::add(i, DELTA_UNIXEPOCH_JANSIX);

		// Get the TAI time.
		// assertion since TT and TAI are continuous.
		append(ret, (tt.convto(&tai, i) as []time::instant)[0]);
		return ret;
	case =>
		return void;
	};
};

fn mtc_convfrom(ts: *timescale, i: time::instant) ([]time::instant | void) = {
	let ret: []time::instant = [];
	switch (ts) {
	case &mtc =>
		append(ret, i);
		return ret;
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
		append(ret, time::add(i, DELTA_MARSEPOCH_JANSIX));
		return ret;
	case =>
		return void;
	};
};


@test fn utc_convto_tai() void = {
	// TODO: skip test if no leapsec data available (!utc_isinitialized)
	// TODO: test negative leapsecs somehow
	let testcases: [](
		(i64, i64), // give
		(void | [0](i64, i64) | [1](i64, i64) | [2](i64, i64)) // expect
	) = [
		((-      1000i64,         0i64), [(-       990i64,         0i64)]),
		((          0i64,         0i64), [(         10i64,         0i64)]),
		((       1000i64,         0i64), [(       1010i64,         0i64)]),
		// 1970 Jan 01
		((   63071998i64,         0i64), [(   63072008i64,         0i64)]),
		((   63071998i64, 500000000i64), [(   63072008i64, 500000000i64)]),
		((   63071999i64,         0i64), [(   63072009i64,         0i64)]),
		((   63071999i64, 500000000i64), [(   63072009i64, 500000000i64)]),
		((   63072000i64,         0i64), [(   63072010i64,         0i64)]),
		((   63072000i64, 500000000i64), [(   63072010i64, 500000000i64)]),
		((   63072001i64,         0i64), [(   63072011i64,         0i64)]),
		((   63072001i64, 500000000i64), [(   63072011i64, 500000000i64)]),
		((   63072002i64,         0i64), [(   63072012i64,         0i64)]),
		// 1981 Jul 01
		((  362793598i64,         0i64), [(  362793617i64,         0i64)]),
		((  362793598i64, 500000000i64), [(  362793617i64, 500000000i64)]),
		((  362793599i64,         0i64), [
			(  362793618i64,         0i64),
			(  362793619i64,         0i64),
		]),
		((  362793599i64, 500000000i64), [
			(  362793618i64, 500000000i64),
			(  362793619i64, 500000000i64),
		]),
		((  362793600i64,         0i64), [(  362793620i64,         0i64)]),
		((  362793600i64, 500000000i64), [(  362793620i64, 500000000i64)]),
		((  362793601i64,         0i64), [(  362793621i64,         0i64)]),
		((  362793601i64, 500000000i64), [(  362793621i64, 500000000i64)]),
		((  362793602i64,         0i64), [(  362793622i64,         0i64)]),
		// 2017 Jan 01
		(( 1483228798i64,         0i64), [( 1483228834i64,         0i64)]),
		(( 1483228798i64, 500000000i64), [( 1483228834i64, 500000000i64)]),
		(( 1483228799i64,         0i64), [
			( 1483228835i64,         0i64),
			( 1483228836i64,         0i64),
		]),
		(( 1483228799i64, 500000000i64), [
			( 1483228835i64, 500000000i64),
			( 1483228836i64, 500000000i64),
		]),
		(( 1483228800i64,         0i64), [( 1483228837i64,         0i64)]),
		(( 1483228800i64, 500000000i64), [( 1483228837i64, 500000000i64)]),
		(( 1483228801i64,         0i64), [( 1483228838i64,         0i64)]),
		(( 1483228801i64, 500000000i64), [( 1483228838i64, 500000000i64)]),
		(( 1483228802i64,         0i64), [( 1483228839i64,         0i64)]),
	];

	for (let testcase .. testcases) {
		let params = testcase.0;
		let param = time::instant{ sec = params.0, nsec = params.1 };
		let expect = testcase.1;
		let actual = utc_convto(&tai, param);

		match (expect) {
		case void =>
			assert(actual is void);

		case [0](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 0);

		case let insts: [1](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 1);
			assert(0 == time::compare(
				actual[0],
				time::instant{
					sec = insts[0].0,
					nsec = insts[0].1,
				},
			));

		case let insts: [2](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 2);
			assert(0 == time::compare(
				actual[0],
				time::instant{
					sec = insts[0].0,
					nsec = insts[0].1,
				},
			));
			assert(0 == time::compare(
				actual[1],
				time::instant{
					sec = insts[1].0,
					nsec = insts[1].1,
				},
			));
		};
	};
};

@test fn utc_convfrom_tai() void = {
	// TODO: skip test if no leapsec data available (!utc_isinitialized)
	// TODO: test negative leapsecs somehow
	let testcases: [](
		(i64, i64), // give
		(void | [0](i64, i64) | [1](i64, i64) | [2](i64, i64)) // expect
	) = [
		((-       990i64,         0i64), [(-      1000i64,         0i64)]),
		((         10i64,         0i64), [(          0i64,         0i64)]),
		((       1010i64,         0i64), [(       1000i64,         0i64)]),
		// 1970 Jan 01
		((   63072008i64,         0i64), [(   63071998i64,         0i64)]),
		((   63072008i64, 500000000i64), [(   63071998i64, 500000000i64)]),
		((   63072009i64,         0i64), [(   63071999i64,         0i64)]),
		((   63072009i64, 500000000i64), [(   63071999i64, 500000000i64)]),
		((   63072010i64,         0i64), [(   63072000i64,         0i64)]),
		((   63072010i64, 500000000i64), [(   63072000i64, 500000000i64)]),
		((   63072011i64,         0i64), [(   63072001i64,         0i64)]),
		((   63072011i64, 500000000i64), [(   63072001i64, 500000000i64)]),
		((   63072012i64,         0i64), [(   63072002i64,         0i64)]),
		// 1981 Jul 01
		((  362793617i64,         0i64), [(  362793598i64,         0i64)]),
		((  362793617i64, 500000000i64), [(  362793598i64, 500000000i64)]),
		((  362793618i64,         0i64), [(  362793599i64,         0i64)]),
		((  362793618i64, 500000000i64), [(  362793599i64, 500000000i64)]),
		((  362793619i64,         0i64), [(  362793599i64,         0i64)]),
		((  362793619i64, 500000000i64), [(  362793599i64, 500000000i64)]),
		((  362793620i64,         0i64), [(  362793600i64,         0i64)]),
		((  362793620i64, 500000000i64), [(  362793600i64, 500000000i64)]),
		((  362793621i64,         0i64), [(  362793601i64,         0i64)]),
		((  362793621i64, 500000000i64), [(  362793601i64, 500000000i64)]),
		((  362793622i64,         0i64), [(  362793602i64,         0i64)]),
		// 2017 Jan 01
		(( 1483228834i64,         0i64), [( 1483228798i64,         0i64)]),
		(( 1483228834i64, 500000000i64), [( 1483228798i64, 500000000i64)]),
		(( 1483228835i64,         0i64), [( 1483228799i64,         0i64)]),
		(( 1483228835i64, 500000000i64), [( 1483228799i64, 500000000i64)]),
		(( 1483228836i64,         0i64), [( 1483228799i64,         0i64)]),
		(( 1483228836i64, 500000000i64), [( 1483228799i64, 500000000i64)]),
		(( 1483228837i64,         0i64), [( 1483228800i64,         0i64)]),
		(( 1483228837i64, 500000000i64), [( 1483228800i64, 500000000i64)]),
		(( 1483228838i64,         0i64), [( 1483228801i64,         0i64)]),
		(( 1483228838i64, 500000000i64), [( 1483228801i64, 500000000i64)]),
		(( 1483228839i64,         0i64), [( 1483228802i64,         0i64)]),
	];

	for (let testcase .. testcases) {
		let params = testcase.0;
		let param = time::instant{ sec = params.0, nsec = params.1 };
		let expect = testcase.1;
		let actual = utc_convfrom(&tai, param);

		match (expect) {
		case void =>
			assert(actual is void);

		case [0](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 0);

		case let insts: [1](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 1);
			assert(0 == time::compare(
				actual[0],
				time::instant{
					sec = insts[0].0,
					nsec = insts[0].1,
				},
			));

		case let insts: [2](i64, i64) =>
			assert(actual is []time::instant);
			const actual = actual as []time::instant;
			assert(len(actual) == 2);
			assert(0 == time::compare(
				actual[0],
				time::instant{
					sec = insts[0].0,
					nsec = insts[0].1,
				},
			));
			assert(0 == time::compare(
				actual[1],
				time::instant{
					sec = insts[1].0,
					nsec = insts[1].1,
				},
			));
		};
	};
};
