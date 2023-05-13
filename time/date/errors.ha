// License: MPL-2.0
// (c) 2023 Byron Torres <b@torresjrjr.com>

// All possible errors returned from [[date]].
export type error = !(insufficient | invalid | parsefail);

// Converts an [[error]] into a human-friendly string.
export fn strerror(err: error) const str = {
	match (err) {
	case insufficient =>
		return "Insufficient date information";
	case invalid =>
		return "Invalid date information";
	case let rn: parsefail =>
		// TODO: use rune 'rn' here
		return "Date parsing error";
	};
};
