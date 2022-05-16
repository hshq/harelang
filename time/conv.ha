// Converts a given [[instant]] to a Unix timestamp.
// Note, nanosecond information is lost during conversion.
export fn unix(a: instant) i64 = a.sec;

// Converts a given Unix timestamp to an [[instant]].
export fn from_unix(u: i64) instant = instant {
	sec = u,
	nsec = 0,
};
