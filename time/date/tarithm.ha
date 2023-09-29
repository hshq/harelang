// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;

// Adds a [[time::duration]] to a [[date]] with [[time::add]]. This is a
// timescalar aritmetic operation.
//
// See [[reckon]].
export fn add(d: date, x: time::duration) date = {
	return from_instant(d.loc, time::add(*(&d: *time::instant), x));
};
