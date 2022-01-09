use time;
use time::chrono;
use datetime;

// Parses and retrieves a [[chrono::timezone]] from the system zoneinfo
// database, or if applicable, from an internal selection of timezones.
export fn tz(id: str) chrono::locality = {
	switch (id) {
	case "Local" =>
		return chrono::local;
	case "UTC" =>
		return chrono::UTC_Z;
	case "TAI" =>
		return chrono::TAI_Z;
	case "MTC" =>
		return chrono::MTC_Z;
	case =>
		void;
	};

	// TODO: temporary
	if (id == "Europe/Amsterdam") {
		return TZ_Europe__Amsterdam;
	};

	return chrono::local;
};

// TODO: Here are some temporary timezones until a full parser is written

// Europe/Amsterdam timezone
export const TZ_Europe__Amsterdam: chrono::locality = &tz_europe__amsterdam;

const tz_europe__amsterdam: chrono::timezone = chrono::timezone{
	name = "Europe/Amsterdam",
	timescale = &chrono::UTC,
	daylength = chrono::EARTH_DAY,
	zones = [
		chrono::zone {
			zoffset = 1 * time::HOUR,
			name = "Central European Time",
			abbrev = "CET",
			dst = false,
		},
		chrono::zone {
			zoffset = 2 * time::HOUR,
			name = "Central European Summer Time",
			abbrev = "CEST",
			dst = true,
		},
	],
	transitions = [],
};

// CET (Central European Time) timezone
export const TZ_CET: chrono::locality = &tz_cet;

const tz_cet: chrono::timezone = chrono::timezone{
	name = "CET",
	timescale = &chrono::UTC,
	daylength = chrono::EARTH_DAY,
	zones = [
		chrono::zone {
			zoffset = 1 * time::HOUR,
			name = "Central European Time",
			abbrev = "CET",
			dst = false,
		},
		chrono::zone {
			zoffset = 2 * time::HOUR,
			name = "Central European Summer Time",
			abbrev = "CEST",
			dst = true,
		},
	],
	transitions = [],
};
