// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;

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

// Returns true if moments a & b are equivalent; otherwise, returns false.
//
// The moments are compared as [[time::instant]]s; their observed chronological
// values are ignored.
//
// If the moments' associated [[timescale]]s are different, they will be
// converted to [[tai]] instants first. Any [[discontinuity]] occurence will be
// returned. If a discontinuity against TAI amongst the two timescales exist,
// consider converting such instants manually.
export fn eq(a: *moment, b: *moment) (bool | discontinuity) = {
	return 0 == compare(a, b)?;
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
