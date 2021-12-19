use time;

// A date & time within a locality, to be contextualised in a chronology
export type moment = struct {
	date: epochal,
	time: time::duration,
	loc: locality,
	tz: (*timezone | local),
};

// An ordinal day on earth since the calendar epoch (zeroth day) 1970-01-01
export type epochal = i64;
