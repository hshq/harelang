use time::chrono;

// Represents an ISO calendar date.
// Instances created from isocal:: functions are guaranteed to be valid.
export type localdate = struct {
	era:      (void | int),
	year:     (void | int),
	month:    (void | int),
	day:      (void | int),
	weekyear: (void | int),
	week:     (void | int),
	weekday:  (void | int),
	yearday:  (void | int),
};

export fn conv_epochal_localdate(epochal: chrono::epochal) localdate = {
	// Algorithm adapted from:
	// https://en.wikipedia.org/wiki/Julian_day#Julian_or_Gregorian_calendar_from_Julian_day_number
	//
	// Alternate methods of date calculation should be explored.
	const J = epochal - EPOCH_JULIAN;
	const j = 1401;
	const y = 4716;
	const B = 274277;
	const C = -38;
	const r = 4;
	const v = 3;
	const p = 1461;
	const u = 5;
	const w = 2;
	const s = 153;
	const n = 12;
	const m = 2;

	const f = J + j + (((4 * J + B) / 146097) * 3) / 4 + C;
	const e = r * f + v;
	const g = (e % p) / r;
	const h = u * g + w;

	const D = (h % s) / u + 1;
	const M = ((h / s + m) % n) + 1;
	const Y = (e / p) - y + (n + m - M) / n;

	const ld = localdate {
		year = Y: int,
		month = M: int,
		day = D: int,
	};
	return ld;
};

export fn conv_localdate_epochal(ld: localdate) chrono::epochal = {
	const Y = ld.year as int;
	const M = ld.month as int;
	const D = ld.day as int;
	const jdn = (
		(1461 * (Y + 4800 + (M - 14) / 12)) / 4
		+ (367 * (M - 2 - 12 * ((M - 14) / 12))) / 12
		- (3 * ((Y + 4900 + (M - 14) / 12) / 100)) / 4
		+ D
		- 32075
	);
	const epochal = jdn + EPOCH_JULIAN;
	return epochal;
};
