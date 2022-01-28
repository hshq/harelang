use time;
use time::chrono;

// Transforms and creates a new [[datetime]] in a different [[chrono::locality]]
export fn in(loc: chrono::locality, dt: datetime) datetime = {
	const old = to_moment(dt);
	const new = chrono::in(loc, old);
	const new_dt = from_moment(new);
	return new_dt;
};

// Returns a fictitious [[datetime]] which is adjusted and normalized as if its
// locality was the normal locality. Its fields are adjusted by its current
// [[chrono::zone]]'s offset.
//
// This is a utility function for use by other modules's internal calculations.
// You probably shouldn't use this directly.
//
// TODO: Rename [[localize]] to something less confusing and more dangerous
// sounding? Perhaps not export it? It's use is special case and often not
// what users want.
export fn localize(dt: datetime) datetime = {
	return from_moment(chrono::localize(to_moment(dt)));
};

// Finds and returns a [[datetime]]'s currently observed zone
export fn lookupzone(dt: *datetime) chrono::zone = {
	const m = to_moment(*dt);
	const z = chrono::lookupzone(&m);
	dt.zone = z;
	return z;
};
