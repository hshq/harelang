// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use time;
use math;

// Invalid [[moment]].
export type invalid = !void;

// A moment in time within a [[locality]]. Create one with [[new]].
//
// Moments extend the [[time::instant]] type and couples it with a [[timescale]]
// via the .loc field.
//
// Moments observe a [[date]], time-of-day, and [[zone]], which are evaluated
// and accessed by the [[getdate]], [[gettime]], and [[getzone]] functions.
//
// The [[time::chrono]] modules implements a small chronology of dates & times.
// Higher level modules like [[datetime]] expand upon this with more complex
// chronological values (years, hours, etc.). The [[datetime::datetime]] type
// embeds this type, and other modules implementing other chronologies may
// interoperate by passing pointers.
export type moment = struct {
	// The embedded [[time::instant]] of this moment
	time::instant,

	// The [[locality]] with which to interpret this moment
	loc: locality,

	// The observed ordinal day (on Earth or otherwise)
	// since an abitrary epoch, like the Hare epoch 1970-01-01
	date: (date | void),

	// The observed time since the start of the day
	time: (time::duration | void),

	// The observed [[zone]]
	zone: (zone | void),
};

// An ordinal day since an epoch. The Hare epoch (zeroth day) 1970 Jan 1st is
// used for terrestrial chronologies.
export type date = i64;

// Creates a new [[moment]].
export fn new(loc: locality, inst: time::instant) moment = {
	return moment {
		loc = loc,
		sec = inst.sec,
		nsec = inst.nsec,
		date = void,
		time = void,
		zone = void,
	};
};

// Evalutes, caches, and returns a [[moment]]'s observed [[zone]].
export fn getzone(m: *moment) zone = {
	match (m.zone) {
	case let z: zone =>
		return z;
	case void =>
		return lookupzone(m);
	};
};

// Evaluates, caches, and returns a [[moment]]'s observed epochal date.
export fn getdate(m: *moment) date = {
	match (m.date) {
	case let d: date =>
		return d;
	case void =>
		return eval_datetime(m).0;
	};
};

// Evaluates, caches, and returns a [[moment]]'s observed time-of-day as a
// [[time::duration]] since the start of a day.
export fn gettime(m: *moment) time::duration = {
	match (m.time) {
	case let t: time::duration =>
		return t;
	case void =>
		return eval_datetime(m).1;
	};
};

// Evaluates, caches, and returns a [[moment]]'s observed date & time.
fn eval_datetime(m: *moment) (date, time::duration) = {
	const i = time::add(*(m: *time::instant), getzone(m).zoffset);
	const day = m.loc.daylength;
	const daysec = day / time::SECOND;
	const d = if (i.sec >= 0) i.sec / daysec else (i.sec + 1) / daysec - 1;
	const t = ((i.sec % daysec + daysec) * time::SECOND + i.nsec) % day;
	m.time = t;
	m.date = d;
	return (d, t);
};

// Creates a [[moment]] from a given [[locality]], zone offset, [[date]] and
// time-of-day.
export fn from_datetime(
	loc: locality,
	zo: time::duration,
	d: date,
	t: time::duration,
) moment = {
	const inst = calc_instant(loc.daylength, zo, d, t);
	return moment {
		loc = loc,
		sec = inst.sec,
		nsec = inst.nsec,
		date = d,
		time = t,
		zone = void
	};
};

fn calc_instant(
	day: time::duration, // length of a day
	zo: time::duration,  // zone offset
	d: date,             // date since epoch
	t: time::duration,   // time since start of day
) time::instant = {
	// TODO: make sure this works across transitions
	const daysec = (day / time::SECOND): i64;
	const dayrem = day % time::SECOND;
	let i = time::instant {
		sec = d * daysec,
		nsec = 0,
	};
	i = time::add(i, d: i64 * dayrem);
	i = time::add(i, t);
	i = time::add(i, -zo);
	return i;
};

// The duration of a day on Earth, in terrestrial (SI) seconds.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in Martian seconds.
export def MARS_SOL_MARTIAN: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in terrestrial (SI) seconds.
export def MARS_SOL_TERRESTRIAL: time::duration = (88775.244147 * time::SECOND: f64): time::duration;
