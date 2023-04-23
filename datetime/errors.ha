// License: MPL-2.0
// (c) 2023 Byron Torres <b@torresjrjr.com>

// All possible errors returned from [[datetime]].
export type error = !(insufficient | invalid | parsefail);

// Converts an [[error]] into a human-friendly string.
export fn strerror(err: error) const str = {
	match (err) {
	case insufficient =>
		return "Insufficient datetime information";
	case invalid =>
		return "Invalid datetime information";
	case let rn: parsefail =>
		// TODO: use rune 'rn' here
		return "Datetime parsing error";
	};
};
