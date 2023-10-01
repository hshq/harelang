// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;

// Signature verification failed.
export type badsig = !void;

// A tagged union of all RSA error types.
export type error = !(
	badsig |
	errors::overflow |
	errors::invalid
);

// Converts an [[error]] into a human-friendly string representation.
export fn strerror(err: error) str = {
	match (err) {
	case badsig =>
		return "Signature verification failed";
	case errors::overflow =>
		return "Key or key operation exceeds given buffer size";
	case errors::invalid =>
		return errors::strerror(errors::invalid);
	};
};
