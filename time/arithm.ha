// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;

// Adds a [[duration]] to an [[instant]], returning an instant further in the
// future (given a positive duration), or further in the past (given a negative
// duration).
export fn add(i: instant, x: duration) instant = {
	if (x == 0) {
		return i;
	} else if (x > 0) {
		return instant {
			sec = i.sec + (i.nsec + x) / SECOND,
			nsec = (i.nsec + x) % SECOND,
		};
	} else {
		return instant {
			sec = i.sec + (i.nsec + x - SECOND + NANOSECOND) / SECOND,
			nsec = (i.nsec + (x % SECOND) + SECOND) % SECOND,
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

// Scales the given [[instant]]'s scalar value by a factor 'f'. Make sure to
// know what epoch you're dealing with.
export fn mult(i: instant, f: f64) instant = {
	// use positive numbers for convenience
	const positive = if (i.sec < 0 ^^ f < 0.0) false else true;
	const f = if (f < 0.0) -f else f;
	const asec: i64 = if (i.sec < 0) -i.sec - 1 else i.sec;
	const ansec: i64 = if (i.sec < 0) SECOND - i.nsec else i.nsec;

	// initial multiply
	const fsec = (asec: f64 * f);
	const bsec = fsec: i64;
	const fnsec = (ansec: f64 * f);
	const bnsec = fnsec: i64;

	// get seconds overflow (nsec remainder)
	const secrem = math::modf64(fsec, 1.0);
	const addnsec = (secrem * SECOND: f64): i64;

	// add overflows
	const b = instant {
		sec = bsec,
		nsec = ansec,
	};
	const b = add(b, bnsec - ansec); // add nsec overflow
	const b = add(b, addnsec);       // add sec overflow

	// switch back to original sign
	const b = if (positive) {
		yield b;
	} else {
		yield instant {
			sec = -b.sec - 1,
			nsec = SECOND - b.nsec,
		};
	};

	return b;
};

@test fn add() void = {
	const cases = [
	//	instant a        duration x    instant b
		( 0,         0,  -2000000001,  -3, 999999999),
		( 0,         0,  -2000000000,  -2,         0),
		( 0,         0,  -1999999999,  -2,         1),
		( 0,         0,  -1000000001,  -2, 999999999),
		( 0,         0,  -1000000000,  -1,         0),
		( 0,         0,   -999999999,  -1,         1),
		( 0,         0,           -1,  -1, 999999999),
		( 0,         0,            0,   0,         0),
		( 0,         0,            1,   0,         1),
		( 0,         0,    999999999,   0, 999999999),
		( 0,         0,   1000000000,   1,         0),
		( 0,         0,   1000000001,   1,         1),
		( 0,         0,   1999999999,   1, 999999999),
		( 0,         0,   2000000000,   2,         0),
		( 0,         0,   2000000001,   2,         1),

		( 0,         1,  -2000000001,  -2,         0),
		( 0,         1,  -2000000000,  -2,         1),
		( 0,         1,  -1999999999,  -2,         2),
		( 0,         1,  -1000000001,  -1,         0),
		( 0,         1,  -1000000000,  -1,         1),
		( 0,         1,   -999999999,  -1,         2),
		( 0,         1,           -1,   0,         0),
		( 0,         1,            0,   0,         1),
		( 0,         1,            1,   0,         2),
		( 0,         1,    999999999,   1,         0),
		( 0,         1,   1000000000,   1,         1),
		( 0,         1,   1000000001,   1,         2),
		( 0,         1,   1999999999,   2,         0),
		( 0,         1,   2000000000,   2,         1),
		( 0,         1,   2000000001,   2,         2),

		(-1, 999999999,  -2000000001,  -3, 999999998),
		(-1, 999999999,  -2000000000,  -3, 999999999),
		(-1, 999999999,  -1999999999,  -2,         0),
		(-1, 999999999,  -1000000001,  -2, 999999998),
		(-1, 999999999,  -1000000000,  -2, 999999999),
		(-1, 999999999,  - 999999999,  -1,         0),
		(-1, 999999999,           -1,  -1, 999999998),
		(-1, 999999999,            0,  -1, 999999999),
		(-1, 999999999,            1,   0,         0),
		(-1, 999999999,    999999999,   0, 999999998),
		(-1, 999999999,   1000000000,   0, 999999999),
		(-1, 999999999,   1000000001,   1,         0),
		(-1, 999999999,   1999999999,   1, 999999998),
		(-1, 999999999,   2000000000,   1, 999999999),
		(-1, 999999999,   2000000001,   2,         0),

		( 0, 999999999,  -2000000001,  -2, 999999998),
		( 0, 999999999,  -2000000000,  -2, 999999999),
		( 0, 999999999,  -1999999999,  -1,         0),
		( 0, 999999999,  -1000000001,  -1, 999999998),
		( 0, 999999999,  -1000000000,  -1, 999999999),
		( 0, 999999999,   -999999999,   0,         0),
		( 0, 999999999,           -1,   0, 999999998),
		( 0, 999999999,            0,   0, 999999999),
		( 0, 999999999,            1,   1,         0),
		( 0, 999999999,    999999999,   1, 999999998),
		( 0, 999999999,   1000000000,   1, 999999999),
		( 0, 999999999,   1000000001,   2,         0),
		( 0, 999999999,   1999999999,   2, 999999998),
		( 0, 999999999,   2000000000,   2, 999999999),
		( 0, 999999999,   2000000001,   3,         0),
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const C = cases[i];
		const a = instant { sec = C.0, nsec = C.1 };
		const x = C.2;
		const b = instant { sec = C.3, nsec = C.4 };
		const B = add(a, x);
		assert(B.sec == b.sec, "time::add() .sec error");
		assert(B.nsec == b.nsec, "time::add() .nsec error");
	};
};

@test fn compare() void = {
	let a = now(clock::MONOTONIC);
	sleep(1 * MILLISECOND);
	let b = now(clock::MONOTONIC);
	assert(compare(a, b) < 0);
	assert(compare(b, a) > 0);
	assert(compare(a, a) == 0);
};

@test fn mult() void = {
	const cases = [
	//	instant a        factor f      instant b    interpretations
		( 0,         0,  0.000,   0,         0), //  0.000000000
		( 9,         0,  0.000,   0,         0), //  0.000000000
		( 0, 999999999,  0.000,   0,         0), //  0.000000000
		( 9, 999999999,  0.000,   0,         0), //  0.000000000

		( 1,         0,  1.000,   1,         0), //  1.000000000
		( 9,         0,  1.000,   9,         0), //  9.000000000
		( 1, 999999999,  1.000,   1, 999999999), //  1.999999999
		( 9, 999999999,  1.000,   9, 999999999), //  9.999999999

		( 1,         0,  0.001,   0,   1000000), //  0.001000000
		( 1,         0,  0.010,   0,  10000000), //  0.010000000
		( 1,         0,  0.100,   0, 100000000), //  0.100000000

		(-1,         0,  0.001,  -1, 999000000), // -0.001000000
		(-1,         0,  0.010,  -1, 990000000), // -0.010000000
		(-1,         0,  0.100,  -1, 900000000), // -0.100000000
		(-1,         0,  1.000,  -1,         0), // -1.000000000

		( 0, 500000000,  0.001,   0,    500000), //  0.005000000
		( 0, 500000000,  0.010,   0,   5000000), //  0.050000000
		( 0, 500000000,  0.100,   0,  50000000), //  0.500000000

		( 2,         0,  0.001,   0,   2000000), //  0.002000000
		( 2,         0,  0.010,   0,  20000000), //  0.020000000
		( 2,         0,  0.100,   0, 200000000), //  0.200000000

		( 3, 141592653,  3.141,   9, 867742523), //  9.867742523073
		( 2, 718281828,  2.718,   7, 388290007), //  7.388290008504 (rounds down?)
		( 1, 414213562,  1.414,   1, 999697975), //  1.999697976668 (rounds down?)

		( 3, 141592653, -3.141, -10, 132257477), // -9.867742523073
		( 2, 718281828, -2.718,  -8, 611709993), // -7.388290008504
		( 1, 414213562, -1.414,  -2,    302025), // -1.999697976668

		(-4, 858407347,  3.141, -10, 132257477), // -9.867742523073
		(-3, 281718172,  2.718,  -8, 611709993), // -7.388290008504
		(-2, 585786438,  1.414,  -2,    302025), // -1.999697976668

		(-4, 858407347, -3.141,   9, 867742523), //  9.867742523073
		(-3, 281718172, -2.718,   7, 388290007), //  7.388290008504
		(-2, 585786438, -1.414,   1, 999697975), //  1.999697976668
	];

	for (let i = 0z; i < len(cases); i += 1) {
		const C = cases[i];
		const a = instant { sec = C.0, nsec = C.1 };
		const f = C.2;
		const b = instant { sec = C.3, nsec = C.4 };
		const B = mult(a, f);
		assert(B.sec == b.sec, "time::mult() .sec error");
		assert(B.nsec == b.nsec, "time::mult() .nsec error");
	};
};
