use time;

//	// A chronological system for ordering days as dates and eras
//	export type chronology = struct {
//		to_taidate: nullable *fn(n: moment) moment,
//		from_taidate: nullable *fn(n: moment) moment,
//	
//		scale: timescale,
//	};

// A date & time within a locality, to be contextualised in a chronology
export type moment = struct {
	date: epochal,
	time: time::duration,
	loc: locality,
};

// An ordinal day on earth since the calendar epoch (zeroth day) 1970-01-01
//
// Notes:
// 1970-01-01 is "the Hare date-epoch". It was chosen out of simplicity to match
// the UNIX timescale epoch. This shouldn't affect performance in calendar
// implementations because they can convert to other epochs if they so desire.
// (as of writing) datetime:: converts to the Julian epoch for calculations.
export type epochal = i64;
