use time;

// UTC timestamps and their TAI offsets, sourced from leap-seconds.list
// updated: 8 July 2016
// expires: 28 June 2022
//
// TODO:
// this is a temporary hard-coded list. read leap-second data from a source.
//
// Separating concerns of timezones and timescale has proven troublesome, since
// data of timezone transitions and leap seconds are both encoded in the TZif
// files generated from the Olson/tz project, and typically installed at
// /usr/share/zoneinfo. Thus, for typical programs in a minimal system like
// Alpine, the entire system can only be configured to run either with or
// without adherence to leap second information.
//
// Olson himself has expressed for the support of Martian time, which with our
// approach, may depend on multi-timescale support:
//
// > The tz database does not currently support Mars time, but it is documented
// > here in the hopes that support will be added eventually. 8
//
// Some systems have an ideal /usr/share/zoneinfo/leap-seconds.list file, which
// is directly downloaded from a periodically maintained file at
// <ftp://ftp.nist.gov/pub/time/leap-seconds.list> or
// <ftp://ftp.boulder.nist.gov/pub/time/leap-seconds.list>. This file contains a
// list of Unix timestamps (2272060800) and absolute timescale offsets (+10). A
// good solution ought to use this.
//
// Some systems have a less ideal /usr/share/zoneinfo/leapseconds file, which is
// generated from leap-seconds.list using an awk script, and contains Gregorian
// datetime timestamps (1972 Jun 30 23:59:60) and relative timescale corrections
// (+S, -S). This may be a fallback solution.
const leaps_utc: [](i64, i64) = [
	(2272060800, 10),
	(2287785600, 11),
	(2303683200, 12),
	(2335219200, 13),
	(2366755200, 14),
	(2398291200, 15),
	(2429913600, 16),
	(2461449600, 17),
	(2492985600, 18),
	(2524521600, 19),
	(2571782400, 20),
	(2603318400, 21),
	(2634854400, 22),
	(2698012800, 23),
	(2776982400, 24),
	(2840140800, 25),
	(2871676800, 26),
	(2918937600, 27),
	(2950473600, 28),
	(2982009600, 29),
	(3029443200, 30),
	(3076704000, 31),
	(3124137600, 32),
	(3345062400, 33),
	(3439756800, 34),
	(3550089600, 35),
	(3644697600, 36),
	(3692217600, 37),
];
