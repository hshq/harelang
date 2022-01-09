use time;
use time::chrono;

// Transforms and creates a new [[datetime]] in a different [[chrono::locality]]
export fn in(loc: chrono::locality, dt: datetime) datetime = {
	// TODO
	const old = to_moment(dt);
	const new = chrono::in(loc, old);
	const new_dt = from_moment(new);
	return new_dt;
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
