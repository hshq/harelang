// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

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

// TODO: change the following to defs when compileable.
// https://git.sr.ht/~sircmpwn/harec/tree/211b99a/item/src/typedef.c#L169

// The earliest representable [[instant]].
export const INSTANT_MIN = instant {
	sec = types::I64_MIN,
	nsec = 0,
};

// The latest representable [[instant]].
export const INSTANT_MAX = instant {
	sec = types::I64_MAX,
	nsec = SECOND - 1,
};

// Represents a specific instant in time as seconds (+nanoseconds) since an
// arbitrary epoch. Instants may only be meaningfully compared with other
// instants sourced from the same [[clock]], or handled by the same
// [[time::chrono::timescale]]
export type instant = struct {
	sec: i64,
	nsec: i64,
};

// Represents a unique interval of time between two [[instant]]s.
export type interval = (instant, instant);
