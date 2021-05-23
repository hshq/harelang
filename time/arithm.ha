// Adds a [[duration]] to an [[instant]], returning an instant further in the
// future (given a positive duration), or further in the past (given a negative
// duration).
export fn add(a: instant, b: duration) instant = instant {
	sec = a.sec + b / SECOND,
	nsec = a.nsec + b,
};
