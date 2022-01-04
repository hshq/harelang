use time;

// A date & time, within a locality, intepreted via a chronology
export type moment = struct {
	date: epochal,
	time: time::duration,
	zone: zone,
	loc: locality,
};

// An ordinal day (on Earth or otherwise) since the Hare epoch (zeroth day)
// 1970-01-01
export type epochal = i64;
