// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use path;

// Gets the cache directory for a given module, given the value of 'harecache'.
// The result is statically allocated and will be overwritten on subsequent
// calls. An error is returned if the resulting path would be longer than
// [[path::MAX]].
export fn get_cache(harecache: str, modpath: str) (str | error) = {
	static let buf = path::buffer { ... };
	return path::set(&buf, harecache, modpath)?;
};
