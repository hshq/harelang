use chrono;

// Represents a ISO calendar date
export type localdate = struct {
	year: i64,
	month: int,
	day: int,
};

export fn conv_daynum_localdate(dn: chrono::daynum) localdate = {
	const J = dn;
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
		year = Y,
		month = M: int,
		day = D: int,
	};
	return ld;
};

export fn conv_localdate_daynum(ld: localdate) chrono::daynum = {
	const Y = ld.year;
	const M = ld.month;
	const D = ld.day;
	const jdn = (
		(1461 * (Y + 4000 + (M - 14) / 12)) / 4
		+ (367 * (M - 2 - 12 * ((M - 14) / 12))) / 12
		- (3 * ((Y + 4900 + (M - 14) / 12) / 100)) / 4
		+ D
		- 32075
	);
	const dn = jdn;
	return dn;
};
