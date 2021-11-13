use time;
use time::chrono;

// Represents the locality of a [[datetime]]
//
// Notes: how to expand?
export type locality = (chrono::local | tzrepr);

export type tzrepr = struct {
	name: str,
	abbrev: str,
	zoffset: localtime,
};

// Retrieves a IANA timezone object by name
export fn tzdb(name: str) chrono::timezone = {
	// TODO
	return chrono::timezone { ... };
};


// Europe/Amsterdam timezone
export const TZ_Europe_Amsterdam: chrono::timezone = chrono::timezone {
	aliasof = &TZ_CET,
	name = "Europe/Amsterdam",
	...
};

// Central European Time
export const TZ_CET: chrono::timezone = chrono::timezone {
	aliasof = void,
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
	applied = &zone_cet,
	name = "CET",
};

fn zone_cet(m: chrono::moment) uint = {
	const dt = datetime { ... };
	conv_moment_datetime(m, &dt);
	const dst = (
		dt.date.month: int == 3 &&
		dt.date.day: int == 28 &&
		dt.time.hour: int >= 2
	) || (
		dt.date.month: int > 3 && dt.date.month: int < 8
	) || (
		dt.date.month: int == 8 &&
		dt.date.day: int < 31
	) || (
		dt.date.month: int == 8 &&
		dt.date.day: int == 31 &&
		dt.time.hour: int <= 3
	);

	if (dst) {
		return 1u;
	} else {
		return 0u;
	};
};

