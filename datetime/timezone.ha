use time;
use time::chrono;

// Retrieves a IANA timezone object by name
export fn tzdb(name: str) chrono::timezone = {
	// TODO
	return chrono::timezone { ... };
};


//
// Some example timezones
//

// "CET", "Central European Time" timezone
export const TZ_CET: chrono::timezone = chrono::timezone {
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
