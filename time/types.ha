// The elapsed time between two instants, in nanoseconds. The largest
// representable duration is about 290 years.
export type duration = i64;

export def NANOSECOND: duration		= 1;
export def MICROSECOND: duration	= 1000 * NANOSECOND;
export def MILLISECOND: duration	= 1000 * MICROSECOND;
export def SECOND: duration		= 1000 * MILLISECOND;
export def MINUTE: duration		= 60 * SECOND;
export def HOUR: duration		= 60 * MINUTE;

// TEMPORARY; MAY CHANGE
//
// Represents a specific instant in time as seconds (+nanoseconds) since a given
// epoch. For [clock::REALTIME], the epoch is the Unix epoch: January 1st, 1970,
// at midnight, UTC.
export type time = struct { sec: i64, nsec: i64 };

// The return value is negative if a < b, zero if a == b, and positive if a > b.
export fn compare(a: time, b: time) int = {
	return if (a.sec < b.sec) -1 else if (a.sec > b.sec) 1 else
		if (a.nsec < b.nsec) -1 else if (a.nsec > b.nsec) 1 else 0;
};

// Converts the given [time] to a Unix timestamp.
export fn unix(a: time) i64 = a.sec;

// Returns a [time] from a Unix timestamp.
export fn from_unix(u: i64) time = time {
	sec = u,
	nsec = 0,
};

@test fn compare() void = {
	let a = now(clock::MONOTONIC);
	sleep(1 * MILLISECOND);
	let b = now(clock::MONOTONIC);
	assert(compare(a, b) < 0);
	assert(compare(b, a) > 0);
	assert(compare(a, a) == 0);
};
