// License: MPL-2.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Adds a [[duration]] to an [[instant]], returning an instant further in the
// future (given a positive duration), or further in the past (given a negative
// duration).
export fn add(a: instant, d: duration) instant = instant {
	sec = a.sec + d / SECOND,
	nsec = a.nsec + d,
};

// Returns the [[duration]] from [[instant]] "a" to [[instant]] "b".
export fn diff(a: instant, b: instant) duration = {
	return ((b.sec - a.sec) * SECOND) + (b.nsec - a.nsec);
};

// Returns:
// -1 if a precedes b;
//  0 if a and b are simultaneous;
// +1 if b precedes a;
//
// Notes:
// At first seems superceded by elapsed, but useful when you need values at
// compile time:
// 	switch (compare(a, b)) {
// 	case -1 => ...;
// 	case  0 => ...;
// 	case  1 => ...;
// 	case => abort("Unreachable")
// 	};
//
// Would it be better as an enum, to avoid that abort()?
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
