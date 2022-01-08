use time;

// A date & time, within a locality, intepreted via a chronology
export type moment = struct {
	date: epochal,
	time: time::duration,
	loc: locality,
};

// An ordinal day (on Earth or otherwise) since the Hare epoch (zeroth day)
// 1970-01-01
export type epochal = i64;

// The temporal length of a day on Earth.
// Interpreted with an appropriate timescale like UTC, TAI, GPS.
export def EARTH_DAY: time::duration = 86400 * time::SECOND;

// The following are temporary constants for demonstration of non-terrestrial
// timescales, and should probably be moved to a third-party martian:: library.
//
// TODO: figure out a future-proof naming convention.

// The temporal length of a solar day on Marth, in Martian seconds
export def MARS_MARTIAN_SOL: time::duration = 86400 * time::SECOND;

// The temporal length of a solar day on Marth, in Earth (SI) seconds
export def MARS_TERRESTRIAL_SOL: time::duration = 88775.244147 * time::SECOND;
