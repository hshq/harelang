// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use time;

// Invalid [[moment]].
export type invalid = !void;

// A moment in time, within a [[locality]], interpreted via a chronology.
export type moment = struct {
	// The ordinal day (on Earth or otherwise)
	// since the Hare epoch (zeroth day) 1970-01-01
	date: epochal,

	// The time since the start of the day
	time: time::duration,

	// The timezone used for interpreting a moment's date and time
	loc: locality,

	// The current [[zone]] this moment observes
	zone: zone,
};

// An ordinal day (on Earth or otherwise) since the Hare epoch (zeroth day)
// 1970-01-01.
export type epochal = i64;

// Creates a new [[moment]].
export fn new(
	loc: locality,
	date: epochal,
	time: time::duration,
) (moment | invalid) = {
	if (time > loc.daylength) {
		return invalid;
	};
	const m = moment {
		date = date,
		time = time,
		loc = loc,
		zone = zone { ... },
	};
	lookupzone(&m);
	return m;
};

// Creates a new [[moment]] from a [[time::instant]] in a [[locality]].
export fn from_instant(i: time::instant, loc: locality) moment = {
	const daysec = (loc.daylength / time::SECOND);
	const d = i.sec / daysec;
	const t = (i.sec % daysec) * time::SECOND + i.nsec * time::NANOSECOND;
	assert(t < loc.daylength, "Internal error: time excedes daylength");
	return new(loc, d, t)!;
};

// Creates a new [[time::instant]] from a [[moment]].
export fn to_instant(m: moment) time::instant = {
	const daysec = (m.loc.daylength / time::SECOND);
	const i = time::instant {
		sec = (m.date: i64 * daysec) + (m.time / time::SECOND),
		nsec = m.time % time::SECOND,
	};
	return i;
};

// The duration of a day on Earth, in terrestrial (SI) seconds.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in Martian seconds.
export def MARS_SOL_MARTIAN: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in terrestrial (SI) seconds.
export def MARS_SOL_TERRESTRIAL: time::duration = (88775.244147 * time::SECOND: f64): time::duration;
