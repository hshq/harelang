use time;

// Represents a [[timescale]]-[[calendar]] system for ordering events.
// Allows conversion between [[datetime]] and [[time::instant]] types.
//
// Notes:
// Needs rethinking. Initially, the idea was to have the possibility of multiple
// plug-and-plug calendars, but since hare doesn't have objects, we need to
// deisgn this another way.  Probably, datetime:: will be solely ISO 8601
// Proleptic Gregorian, with TAI, UTC, and UNIX, and then we'll have something
// like datetime::chrono::* for alternative chronologies. 3rd party libraries
// would be similar.
export type chronology = struct {
	timescale: timescale,
	calendar: calendar,
};

