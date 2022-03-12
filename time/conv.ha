// Converts the given [[instant]] to a Unix timestamp.
export fn unix(a: instant) i64 = a.sec;

// Returns a [[instant]] from a Unix timestamp.
export fn from_unix(u: i64) instant = instant {
	sec = u,
	nsec = 0,
};
