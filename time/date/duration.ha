// License: MPL-2.0
// (c) 2023 Byron Torres <b@torresjrjr.com>
use time;

// Adds a [[time::duration]] to a [[date]] with [[time::add]].
//
// See [[reckon]] for a chronology-wise arithmetic operation which uses
// [[period]].
export fn add(a: date, d: time::duration) date = {
	return from_instant(a.loc, time::add(*(&a: *time::instant), d));
};
