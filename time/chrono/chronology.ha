use time;

// A date & time, within a locality, intepreted via a chronology
export type moment = struct {
	// The ordinal day (on Earth or otherwise)
	// since the Hare epoch (zeroth day) 1970-01-01
	date: epochal,

	// The time since the start of the day
	time: time::duration,

	// The timezone used for interpreting a moment's date and time
	//
	// TODO: make locality nullable? would make moment "{ ... }" initable
	// without a "new" function, though all functions would have to default
	// to a particular locality, which might be bad design considering we
	// don't just support UTC_Z.
	loc: locality,

	// The current [[zone]] this moment observes
	zone: zone,
};

// An ordinal day (on Earth or otherwise) since the Hare epoch (zeroth day)
// 1970-01-01
export type epochal = i64;

// Creates a new [[moment]]
//
// TODO: Check for `time` value bounds overflow. Should we:
// a. Return an error?
// b. "Correct" by overflowing? See datetime::new();
export fn new(date: epochal, time: time::duration, loc: locality) moment = {
	const m = moment {
		date = date,
		time = time,
		loc = loc,
		zone = zone { ... },
	};
	lookupzone(&m);
	return m;
};

// Creates a new [[moment]] from a [[time::instant]] in a [[locality]]
export fn from_instant(i: time::instant, loc: locality) moment = {
	const daysec = (loc.daylength / time::SECOND);
	const d = i.sec / daysec;
	const t = (i.sec % daysec) * time::SECOND + i.nsec * time::NANOSECOND;
	return new(d, t, loc);
};

// Creates a new [[time::instant]] from a [[moment]]
export fn to_instant(m: moment) time::instant = {
	const daysec = (m.loc.daylength / time::SECOND);
	const i = time::instant {
		sec = (m.date: i64 * daysec) + (m.time / time::SECOND),
		nsec = m.time % time::SECOND,
	};
	return i;
};

// The temporal length of a day on Earth.
// Interpreted with an appropriate timescale like UTC, TAI, GPS.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The following are temporary constants for demonstration of non-terrestrial
// timescales as proof of feasibility, and should probably be moved to a
// third-party martian:: library.
//
// TODO: figure out a future-proof naming convention.

// The temporal length of a solar day on Marth, in Martian seconds
export def MARS_SOL_MARTIAN: time::duration = 86400 * time::SECOND;

// The temporal length of a solar day on Marth, in Earth (SI) seconds
export def MARS_SOL_TERRESTRIAL: time::duration = 88775.244147 * time::SECOND;
