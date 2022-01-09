use time;
use time::chrono;

// Transforms and creates a new [[datetime]] in a different [[chrono::locality]]
export fn in(loc: chrono::locality, dt: datetime) datetime = {
	const old = to_moment(dt);
	const new = chrono::in(loc, old);
	const new_dt = from_moment(new);
	return new_dt;
};

// Returns a fictitious datetime which assumes it's own locality is the normal
// locality. Its fields are adjusted by its current zone's offset.
export fn localize(dt: datetime) datetime = {
	return from_moment(chrono::localize(to_moment(dt)));
};

// Finds a [[datetime]]'s currently observed zone
export fn lookupzone(dt: *datetime) chrono::zone = {
	const m = to_moment(*dt);
	const z = chrono::lookupzone(&m);
	dt.zone = z;
	return z;
};
