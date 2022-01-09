use time;
use time::chrono;

// Transforms and creates a new [[datetime]] in a different [[chrono::locality]]
export fn in(loc: chrono::locality, dt: datetime) datetime = {
	const old = to_moment(dt);
	const new = chrono::in(loc, old);
	const new_dt = from_moment(new);
	return new_dt;
};
