// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use fmt;
use fs;
use io;

// All possible errors returned from this module.
export type error = !(
	invalid
	| invalidtzif
	| tzdberror
	| discontinuity
	| analytical
);

// Converts an [[error]] into a human-friendly string. The result may be
// statically allocated.
export fn strerror(err: error) const str = {
	match (err) {
	case invalid =>
		return "Invalid moment";
	case invalidtzif =>
		return "Invalid TZif data";
	case let err: tzdberror =>
		static let buf: [1024]u8 = [0...];
		match (err) {
		case let err: fs::error =>
			return fmt::bsprintf(buf,
				"Timezone database error: {}",
				fs::strerror(err),
			);
		case let err: io::error =>
			return fmt::bsprintf(buf,
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
