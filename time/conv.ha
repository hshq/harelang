// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Converts a given [[instant]] to a Unix timestamp.
// Note, nanosecond information is lost during conversion.
export fn unix(i: instant) i64 = i.sec;

// Converts a given Unix timestamp to an [[instant]].
export fn from_unix(u: i64) instant = instant {
	sec = u,
	nsec = 0,
};
