use time;
use time::chrono;

// Transforms and creates a new [[datetime]] in a different [[chrono::locality]]
export fn in(loc: chrono::locality, dt: datetime) datetime = {
	const old = to_moment(dt);
	const new = chrono::in(loc, old);
	const new_dt = from_moment(new);
	return new_dt;
};

// Returns a fictitious [[datetime]] which is shifted in time by a zone offset.
// This is a utility function. Use with caution.
export fn transform(dt: datetime, zo: time::duration) datetime = {
	return from_moment(chrono::transform(to_moment(dt), zo));
};

// Finds and returns a [[datetime]]'s currently observed zone
export fn lookupzone(dt: *datetime) chrono::zone = {
	const m = to_moment(*dt);
	const z = chrono::lookupzone(&m);
	dt.zone = z;
	return z;
};
