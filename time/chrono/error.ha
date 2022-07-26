// License: MPL-2.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
use encoding::utf8;
use fmt;
use fs;
use io;

// All possible errors returned from [[time::chrono]].
export type error = !(invalid | tzdberror | invalidtzif);

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
	};
};
