use time;
use chrono;

// Represents a ISO datetime
//
// Notes:
// Java has good separation of types: A LocalDatetime, ZonedDatetime,
// OffsetDatetime. Python instead reasons about datetimes as being
// timezone-aware/naive. Here's I try to leaverage Hare's type system to combine
// the two.
//
// Putting the date and time related fields into separate typed structs maybe
// isn't a good idea (see `type localdate` below), but I still put it here
// because localtime is often used on it's own, and it makes some sense to have
// a datetime be composed of a date and time.
export type datetime = struct {
	date: localdate,
	time: localtime,
	loc: locality,
};

// Represents a ISO date
export type localdate = struct {
	// days since calendar epoch
	epochday: i64,

	// ISO calendar date
	year: i64,
	month: u8,
	day: u8,

	// ISO week date
	weekyear: i64,
	week: u8,
	weekday: u8,

	// ISO ordinal date
	yearday: uint,
};

// Represents a ISO time of day
export type localtime = struct {
	hour: u8,
	min: u8,
	sec: u8,
	nsec: u64,
};

// Represents the locality of a datetime
//
// Notes:
// `timescale` may not meaningfully belong here. It's here because sometimes ISO
// datetimes like "1999-05-13T12:30:45.125 UTC" exist as a human-readible form
// of a UTC instant, using the ISO calendar, and where localtime.sec ranges only
// from 0-59.
export type locality = (local | zoneoffset | timezone);

// Represents its associated datetime as local
export type local = void;

// Represents a simple, constant offset
//
// Notes:
// Should this be "utcoffset"?
// Should this just be seconds?
export type zoneoffset = time::duration;

// Represents a timezone; a political region with a ruleset regarding offsets
//
// Notes:
// timezone types design needs a lot of thought.  Enum is probably not a good
// idea.  Initially this was a `type enum str {}`, which may have been a worse
// idea.  Maybe we need a `fn tzdb(tz: str)` like other langs' libs.
export type timezone = enum {
	UTC,
	EUROPE_LONDON,
	// ...
};

