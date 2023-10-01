// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use fmt;
use fs;
use io;

// All possible errors returned from [[time::chrono]].
export type error = !(
	invalid
	| invalidtzif
	| tzdberror
	| discontinuity
	| analytical
);

// Converts an [[error]] into a human-friendly string.
export fn strerror(err: error) const str = {
	match (err) {
	case invalid =>
		return "Invalid moment";
	case invalidtzif =>
		return "Invalid TZif data";
	case let err: tzdberror =>
		match (err) {
		case let err: fs::error =>
			return fmt::asprintf(
				"Timezone database error: {}",
				fs::strerror(err),
			);
		case let err: io::error =>
			return fmt::asprintf(
				"Timezone database error: {}",
				io::strerror(err),
			);
		case invalidtzif =>
			return "Timezone database error: Invalid TZif data";
		};
	case discontinuity =>
		return "A timescale discontinuity caused a misconversion";
	case analytical =>
		return "The analyical result of a conversion at a timescale discontinuity";
	};
};
