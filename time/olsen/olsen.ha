use time;
use time::chrono;
use datetime;

fn tz(id: str) *chrono::timezone = {
	// TODO: retrieve timezone from system zoneinfo database
	return chrono::local;
};
