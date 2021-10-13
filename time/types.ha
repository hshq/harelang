// The elapsed time between two instants, in nanoseconds. The largest
// representable duration is about 290 years.
export type duration = i64;

// [[duration]] representing a single nanosecond.
export def NANOSECOND: duration = 1;

// [[duration]] representing a single microsecond.
export def MICROSECOND: duration = 1000 * NANOSECOND;

// [[duration]] representing a single millisecond.
export def MILLISECOND: duration = 1000 * MICROSECOND;

// [[duration]] representing a second.
export def SECOND: duration = 1000 * MILLISECOND;

// [[duration]] representing a minute.
export def MINUTE: duration = 60 * SECOND;

// [[duration]] representing an hour.
export def HOUR: duration = 60 * MINUTE;

// Represents a specific instant in time as seconds (+nanoseconds) since an
// arbitrary epoch. Instants may only be meaningfully compared with other
// instants sourced from the same clock.
export type instant = struct { sec: i64, nsec: i64 };

// The return value is negative if a < b, zero if a == b, and positive if a > b.
export fn compare(a: instant, b: instant) int = {
	return if (a.sec < b.sec) -1 else if (a.sec > b.sec) 1 else
		if (a.nsec < b.nsec) -1 else if (a.nsec > b.nsec) 1 else 0;
};

// Converts the given [[instant]] to a Unix timestamp.
export fn unix(a: instant) i64 = a.sec;

// Returns a [[instant]] from a Unix timestamp.
export fn from_unix(u: i64) instant = instant {
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
