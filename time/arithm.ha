// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Adds a [[duration]] to an [[instant]], returning an instant further in the
// future (given a positive duration), or further in the past (given a negative
// duration).
export fn add(a: instant, d: duration) instant = instant {
	sec = a.sec + d / SECOND,
	nsec = a.nsec + d,
};

// Returns the duration from [[instant]] a to [[instant]] b.
// If a is earlier than b, the duration is positive.
// If a is equivilent to b, the duration is zero.
// If a is later than b, the duration is negative.
export fn diff(a: instant, b: instant) duration = {
	return ((b.sec - a.sec) * SECOND) + (b.nsec - a.nsec);
};
