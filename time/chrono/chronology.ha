// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;

// Invalid [[moment]].
export type invalid = !void;

// A moment in time within a [[locality]]. Create one with [[new]]. This type
// extends the [[time::instant]] type and couples it with a [[timescale]] via
// its [[locality]] field.
//
// This object should be treated as private and immutable. Directly mutating its
// fields causes undefined behavour when used with module functions. Likewise,
// interrogating the fields' type and value (e.g. using match statements) is
// also improper.
//
// Moments observe a daydate, time-of-day, and [[zone]], which are evaluated,
// cached and obtained with the observer functions [[daydate]], [[daytime]], and
// [[ozone]]. These values are derived from the embedded instant and locality
// information, and thus are guaranteed to be valid.
export type moment = struct {
	// The embedded [[time::instant]].
	time::instant,

	// The [[locality]] with which to interpret this moment.
	loc: locality,

	// The observed [[zone]].
	zone: nullable *zone,

	// The observed daydate (scalar day number)
	// since an abitrary epoch (e.g. the Unix epoch 1970-01-01).
	daydate: (void | i64),

	// The observed time-of-day (amount of daytime progressed in a day)
	// as nanoseconds.
	daytime: (void | i64),
};

// Creates a new [[moment]]. Uses a given [[time::instant]] with a [[timescale]]
// associated with a given [[locality]].
export fn new(loc: locality, i: time::instant) moment = {
	return moment {
		sec = i.sec,
		nsec = i.nsec,
		loc = loc,
		zone = null,
		daydate = void,
		daytime = void,
	};
};

// Observes a [[moment]]'s observed [[zone]].
export fn ozone(m: *moment) zone = {
	match (m.zone) {
	case let z: *zone =>
		return *z;
	case null =>
		const z = lookupzone(m.loc, *(m: *time::instant));
		m.zone = z;
		return *z;
	};
};

// Observes a [[moment]]'s observed daydate (day number since epoch).
//
// For moments with [[locality]]s based on the [[utc]], [[tai]], [[gps]], and
// similar timescales, their epoch date should be interpreted as the Unix epoch
// (1970 Janurary 1st). Other timescales may suggest their own interpretations
// applicable to other chronologies.
export fn daydate(m: *moment) i64 = {
	match (m.daydate) {
	case let dd: i64 =>
		return dd;
	case void =>
		const (dd, dt) = calc_datetime(
			m.loc, *(m: *time::instant), ozone(m).zoff,
		);
		m.daytime = dt;
		m.daydate = dd;
		return dd;
	};
};

// Observes a [[moment]]'s observed time-of-day (amount of daytime progressed in
// a day) as nanoseconds.
export fn daytime(m: *moment) i64 = {
	match (m.daytime) {
	case let dt: i64 =>
		return dt;
	case void =>
		const (dd, dt) = calc_datetime(
			m.loc, *(m: *time::instant), ozone(m).zoff,
		);
		m.daytime = dt;
		m.daydate = dd;
		return dt;
	};
};

// Calculates the observed daydate and time-of-day of a [[time::instant]] in a
// [[locality]] at a particular zone offset.
fn calc_datetime(
	loc: locality,
	inst: time::instant,
	zoff: time::duration,
) (i64, time::duration) = {
	const i = time::add(inst, zoff);
	const day = loc.daylength;
	const daysec = day / time::SECOND;
	const dd = if (i.sec >= 0) i.sec / daysec else (i.sec + 1) / daysec - 1;
	const dt = ((i.sec % daysec + daysec) * time::SECOND + i.nsec) % day;
	return (dd, dt);
};

// Creates a [[moment]] from a given [[locality]], zone offset, daydate, and
// time-of-day.
export fn from_datetime(
	loc: locality,
	zo: time::duration,
	dd: i64,
	dt: i64,
) moment = {
	const inst = calc_instant(loc.daylength, zo, dd, dt);
	return moment {
		sec = inst.sec,
		nsec = inst.nsec,
		loc = loc,
		zone = null,
		daydate = dd,
		daytime = dt,
	};
};

fn calc_instant(
	day: time::duration, // length of a day
	zo: time::duration,  // zone offset
	dd: i64,             // date since epoch
	dt: i64,             // time since start of day (ns)
) time::instant = {
	const daysec = (day / time::SECOND): i64;
	const dayrem = day % time::SECOND;
	let i = time::instant {
		sec = dd * daysec,
		nsec = 0,
	};
	i = time::add(i, dd * dayrem);
	i = time::add(i, dt);
	i = time::add(i, -zo);
	return i;
};

// The duration of a day on Earth, in terrestrial (SI) seconds.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in Martian seconds.
export def MARS_SOL_MARTIAN: time::duration = 86400 * time::SECOND;

// The duration of a solar day on Mars, in terrestrial (SI) seconds.
export def MARS_SOL_TERRESTRIAL: time::duration = 88775244147000 * time::NANOSECOND;
