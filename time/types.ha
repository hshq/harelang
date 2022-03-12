// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>

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
export type instant = struct {
	sec: i64,
	nsec: i64,
};

// Represents a unique interval of time between two instants.
export type interval = struct {
	start: instant,
	end: instant,
};
