use time;

// A date & time, within a locality, intepreted via a chronology
export type moment = struct {
	date: epochal,
	time: time::duration,
	zone: zone,
	tz: *timezone,
};

// An ordinal day on earth since the calendar epoch (zeroth day) 1970-01-01
export type epochal = i64;
