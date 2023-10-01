// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;
use time::chrono;

// Creates an equivalent [[date]] with a different
// [[time::chrono::locality]].
//
// The [[time::chrono::discontinuity]] rules from [[time::chrono::in]] apply here.
export fn in(loc: chrono::locality, d: date) (date | chrono::discontinuity) = {
	return from_moment(chrono::in(loc, *(&d: *chrono::moment))?);
};
