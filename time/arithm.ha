// License: MPL-2.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Adds a [[duration]] to an [[instant]], returning an instant further in the
// future (given a positive duration), or further in the past (given a negative
// duration).
export fn add(a: instant, d: duration) instant = {
	if (d == 0) {
		return a;
	} else if (d > 0) {
		return instant {
			sec = a.sec + (a.nsec + d) / SECOND,
			nsec = (a.nsec + d) % SECOND,
		};
	} else {
		return instant {
			sec = a.sec + (a.nsec + d - SECOND + NANOSECOND) / SECOND,
			nsec = (a.nsec + (d % SECOND) + SECOND) % SECOND,
		};
	};
};

// Returns the [[duration]] from [[instant]] "a" to [[instant]] "b".
export fn diff(a: instant, b: instant) duration = {
	return ((b.sec - a.sec) * SECOND) + (b.nsec - a.nsec);
};

// Returns -1 if a precedes b, 0 if a and b are simultaneous, or +1 if b
// precedes a.
export fn compare(a: instant, b: instant) i8 = {
	return if (a.sec < b.sec) -1
	else if (a.sec > b.sec) 1
	else if (a.nsec < b.nsec) -1
	else if (a.nsec > b.nsec) 1
	else 0;
};

@test fn compare() void = {
	let a = now(clock::MONOTONIC);
	sleep(1 * MILLISECOND);
	let b = now(clock::MONOTONIC);
	assert(compare(a, b) < 0);
	assert(compare(b, a) > 0);
	assert(compare(a, a) == 0);
};
