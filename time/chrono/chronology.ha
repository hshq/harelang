// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
use time;

// Invalid [[moment]].
export type invalid = !void;

// A moment in time within a [[locality]]. Create one with [[new]].
//
// Moments extend the [[time::instant]] type and couples it with a [[timescale]]
// via its [[locality]] field.
//
// This object should be treated as private and immutable. Directly mutating its
// fields causes undefined behavour when used with module functions. Likewise,
// interrogating the fields' type and value (e.g. using match statements) is
// also improper.
//
// Moments observe a date, time-of-day, and [[zone]], which are evaluated and
// obtained with the [[date]], [[time]], and [[mzone]] "observe" functions.
// These values are derived from the embedded instant and locality information,
// and thus are guaranteed to be valid.
export type moment = struct {
	// The embedded [[time::instant]] of this moment
	time::instant,

	// The [[locality]] with which to interpret this moment
	loc: locality,

	// The observed [[zone]]
	zone: nullable *zone,

	// The observed ordinal day (on Earth or otherwise)
	// since an abitrary epoch, like the Hare epoch 1970-01-01
	date: (void | i64),

	// The observed time since the start of the day
	time: (void | time::duration),
};

// Creates a new [[moment]]. Uses a given [[time::instant]] with a [[timescale]]
// associated with a given [[locality]].
export fn new(loc: locality, inst: time::instant) moment = {
	return moment {
		sec = inst.sec,
		nsec = inst.nsec,
		loc = loc,
		zone = null,
		date = void,
		time = void,
	};
};

// Evalutes, caches, and returns a [[moment]]'s observed [[zone]].
export fn mzone(m: *moment) zone = {
	match (m.zone) {
	case let z: *zone =>
		return *z;
	case null =>
		const z = _lookupzone(m.loc, *(m: *time::instant));
		m.zone = z;
		return *z;
	};
};

// Evaluates, caches, and returns a [[moment]]'s observed epochal date.
//
// For moments with [[locality]]s based on the [[utc]], [[tai]], [[gps]], and
// similar timescales, their epoch date should be interpreted as the Unix epoch
// (1970 Janurary 1st). Other timescales may suggest their own interpretations
// applicable to other chronologies.
export fn date(m: *moment) i64 = {
	match (m.date) {
	case let d: i64 =>
		return d;
	case void =>
		const (d, t) = calc_datetime(
			m.loc, *(m: *time::instant), mzone(m).zoff,
		);
		m.time = t;
		m.date = d;
		return d;
	};
};

// Evaluates, caches, and returns a [[moment]]'s observed time-of-day as a
// [[time::duration]] since the start of a day.
export fn time(m: *moment) time::duration = {
	match (m.time) {
	case let t: time::duration =>
		return t;
	case void =>
		const (d, t) = calc_datetime(
			m.loc, *(m: *time::instant), mzone(m).zoff,
		);
		m.time = t;
		m.date = d;
		return t;
	};
};

// Calculates the observed date and time-of-day of a [[time::instant]] in a
// [[locality]] at a particular zone offset.
fn calc_datetime(
	loc: locality,
	inst: time::instant,
	zoff: time::duration,
) (i64, time::duration) = {
	const i = time::add(inst, zoff);
	const day = loc.daylength;
	const daysec = day / time::SECOND;
	const d = if (i.sec >= 0) i.sec / daysec else (i.sec + 1) / daysec - 1;
	const t = ((i.sec % daysec + daysec) * time::SECOND + i.nsec) % day;
	return (d, t);
};

// Creates a [[moment]] from a given [[locality]], zone offset, date, and
// time-of-day.
export fn from_datetime(
	loc: locality,
	zo: time::duration,
	d: i64,
	t: time::duration,
) moment = {
	const inst = calc_instant(loc.daylength, zo, d, t);
	return moment {
		sec = inst.sec,
		nsec = inst.nsec,
		loc = loc,
		zone = null,
		date = d,
		time = t,
	};
};

fn calc_instant(
	day: time::duration, // length of a day
	zo: time::duration,  // zone offset
	d: i64,              // date since epoch
	t: time::duration,   // time since start of day
) time::instant = {
	const daysec = (day / time::SECOND): i64;
	const dayrem = day % time::SECOND;
	let i = time::instant {
		sec = d * daysec,
		nsec = 0,
	};
	i = time::add(i, d * dayrem);
	i = time::add(i, t);
	i = time::add(i, -zo);
	return i;
};

// The duration of a day on Earth, in terrestrial (SI) seconds.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in Martian seconds.
export def MARS_SOL_MARTIAN: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in terrestrial (SI) seconds.
export def MARS_SOL_TERRESTRIAL: time::duration = 88775244147000 * time::NANOSECOND;
