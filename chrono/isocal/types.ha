use time;
use chrono;

// // Represents a timezone
// // Allows conversion between datetimes and instances according to a timescale
// export type timezone = struct {
// 	chrono::timezone,
// 	to_tz_utc: nullable *converter,
// 	from_tz_utc: nullable *converter,
// 	to_tz_tai: nullable *converter,
// 	from_tz_tai: nullable *converter,
// };

export type converter = fn(dt: datetime) datetime;

// Represents the locality of a datetime
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
export type timezone = struct {
	timescale: chrono::timescale,
	// TODO
	// func...: *fn...
};
