use time;

// Represents a chronological system for ordering days as dates and eras
export type chronology = struct {
	// MJD = Modified Julian Date
	to_mjd: nullable *fn(day: moment) moment,
	to_moment: nullable *fn(day: moment) moment,
};

// Represents a calendar system for ordering datea and eras
export type calendar = struct {
	// MJDN = Modified Julian Day Number
	// RD = Rata Die
	to_mjdn: nullable *fn(dn: daynum) daynum,
	to_rd: nullable *fn(dn: daynum) daynum,
};

// Represents a moment in time on a calendar; essentially a datetime
export type moment = struct {
	day: daynum,
	time: time::duration,
};

// Represents a Rata Die, an ordinal day since a calendar epoch
//
// Notes:
// aka:
// - epochalday
// - epochal
// - nday
export type daynum = i64;

// Represents the Modified Julian Day Number calendar.
// Not to be confused with the Julian calendar.
export const MJDN: calendar = calendar { ... };

// Represents the Modified Julian Date chronology.
export const MJD: chronology = chronology { ... };
