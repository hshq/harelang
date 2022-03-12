use time;

// Hare uses raw leap second informtion when dealing with the UTC and TAI
// timescales. This information is source from a standard file installed at
// /usr/share/zoneinfo/leap-seconds.list, which itself is fetched from and
// periodically maintained at:
//
// <ftp://ftp.nist.gov/pub/time/leap-seconds.list>
// <ftp://ftp.boulder.nist.gov/pub/time/leap-seconds.list>
//
// This is in contrast to legacy systems which rely on TZif files, which are
// installed typically at /usr/share/zoneinfo, as part of the "Olson" IANA
// Timezone databse. These files couple timezone and leap second information
// into one datablock.
//
// Depending on a system's installation, leap second information may be
// deliberately left out of the TZif files, or duplicated throughout. This
// design also inhibits our ambitions for dealing with multiple, dynamic
// timescales. Therefore, we have decided to take an alternative approach.

// UTC timestamps and their TAI offsets, sourced from leap-seconds.list
// updated: 8 July 2016
// expires: 28 June 2022
//
// TODO: Initialise this data from /usr/share/zoneinfo/leap-seconds.list
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
