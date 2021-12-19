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

// "Europe/Amsterdam" timezone
export const TZ_Europe_Amsterdam: chrono::tzalias = chrono::tzalias {
	name = "Europe/Amsterdam",
	tz = &TZ_CET,
};

// "CET", "Central European Time" timezone
export const TZ_CET: chrono::timezone = chrono::timezone {
	name = "CET",
	scale = &chrono::UTC,
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
	trans = [],
};
