// License: MPL-2.0
// (c) 2021-2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use time;
use time::chrono;

// Creates an equivalent [[datetime]] with a different
// [[time::chrono::locality]].
//
// The [[time::chrono::discontinuity]] rules from [[time::chrono::in]] apply here.
export fn in(loc: chrono::locality, dt: datetime) (datetime | chrono::discontinuity) = {
	return from_moment(chrono::in(loc, *(&dt: *chrono::moment))?);
};
