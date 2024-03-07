// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;

// Returns true if two [[moment]]s represent the same time in the same locality,
// which is to say that their [[locality]] and [[time::instant]] are both equal.
// Their observed values and representations in a chronology should be the same
// in all cases.
//
// See [[simultaneous]] to determine if two moments represent the same moment in
// time regardless of locality.
export fn coincident(a: *moment, b: *moment) bool = {
	return a.loc == b.loc && a.sec == b.sec && a.nsec == b.nsec;
};

// Returns true if two [[moment]]s represent the same moment in time, regardless
// of locality.
//
// The moments are compared as [[time::instant]]s; their observed chronological
// values and representations are ignored.
//
// If the moments' associated [[timescale]]s are different, they will be
// converted to [[tai]] instants first. Any [[discontinuity]] occurence will be
// returned. If a discontinuity against TAI amongst the two timescales exist,
// consider converting such instants manually.
//
// See [[coincident]] to determine if two [[moment]]s are equal with respect to
// both time and locality.
export fn simultaneous(a: *moment, b: *moment) (bool | discontinuity) = {
	return 0 == compare(a, b)?;
};

// Compares two [[moment]]s. Returns -1 if a precedes b, 0 if a and b are
// simultaneous, or +1 if b precedes a.
//
// The moments are compared as [[time::instant]]s; their observed chronological
// values are ignored.
//
// If the moments' associated [[timescale]]s are different, they will be
// converted to [[tai]] instants first. Any [[discontinuity]] occurence will be
// returned. If a discontinuity against TAI amongst the two timescales exist,
// consider converting such instants manually.
export fn compare(a: *moment, b: *moment) (i8 | discontinuity) = {
	const (ia, ib) = convertpair(a, b)?;
	return time::compare(ia, ib);
};

// Returns the [[time::duration]] between two [[moment]]s, from a to b.
//
// The moments are compared as [[time::instant]]s; their observed chronological
// values are ignored.
//
// If the moments' associated [[timescale]]s are different, they will be
// converted to [[tai]] instants first. Any [[discontinuity]] occurence will be
// returned. If a discontinuity against TAI amongst the two timescales exist,
// consider converting such instants manually.
export fn diff(a: *moment, b: *moment) (time::duration | discontinuity) = {
	const (ia, ib) = convertpair(a, b)?;
	return time::diff(ia, ib);
};

// Adds a [[time::duration]] to a [[moment]] with [[time::add]].
export fn add(m: *moment, x: time::duration) moment = {
	return new(m.loc, time::add(*(m: *time::instant), x));
};

fn convertpair(
	a: *moment,
	b: *moment,
) ((time::instant, time::instant) | discontinuity) = {
	let ia = *(a: *time::instant);
	let ib = *(b: *time::instant);

	if (a.loc.timescale != b.loc.timescale) {
		match (convert(ia, a.loc.timescale, &tai)) {
		case let i: time::instant =>
			ia = i;
		case =>
			return discontinuity;
		};

		match (convert(ib, b.loc.timescale, &tai)) {
		case let i: time::instant =>
			ib = i;
		case =>
			return discontinuity;
		};
	};

	return (ia, ib);
};
