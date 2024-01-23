// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use fs;
use os;
use strings;
use time;

// insert a string into a sorted list of strings, deduplicated.
fn insert_uniq(into: *[]str, s: str) void = {
	let i = 0z;
	// the `into` slice is generally small enough that a linear search is
	// fine
	for (i < len(into) && strings::compare(into[i], s) < 0) {
		i += 1;
	};
	if (i == len(into) || into[i] != s) {
		insert(into[i], strings::dup(s));
	};
};

// Checks if the file at 'target' is out-of-date, given a list of dependency
// files, and the last time the deps list changed. If "target" doesn't exist,
// returns true. If any of the deps don't exist, they are skipped.
export fn outdated(target: str, deps: []str, mtime: time::instant) bool = {
	let current = match (os::stat(target)) {
	case fs::error =>
		return true;
	case let stat: fs::filestat =>
		yield stat.mtime;
	};
	if (time::compare(current, mtime) < 0) {
		return true;
	};
	for (let i = 0z; i < len(deps); i += 1) match (os::stat(deps[i])) {
	case fs::error =>
		continue;
	case let stat: fs::filestat =>
		if (time::compare(current, stat.mtime) < 0) {
			return true;
		};
	};
	return false;
};

// Wrapper for [[fs::next]] that only returns valid submodule directories.
export fn next(it: *fs::iterator) (fs::dirent | void | fs::error) = {
	for (true) match (fs::next(it)?) {
	case void =>
		return void;
	case let d: fs::dirent =>
		if (!fs::isdir(d.ftype)) {
			continue;
		};
		if (is_submodule(d.name)) {
			return d;
		};
	};
};

fn is_submodule(path: str) bool = {
	let it = strings::iter(path);
	for (let first = true; true; first = false) match (strings::next(&it)) {
	case void =>
		break;
	case let r: rune =>
		if (!ascii::isalpha(r) && r != '_'
				&& (first || !ascii::isdigit(r))) {
			return false;
		};
	};
	return true;
};
