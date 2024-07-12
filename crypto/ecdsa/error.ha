// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Invalid key.
export type invalidkey = !void;

// Invalid signature.
export type invalidsig = !void;

// Possible ecdsa errors.
export type error = !(invalidkey | invalidsig);

// String representation of error 'e'.
export fn strerror(e: error) str = {
	match (e) {
	case invalidkey =>
		return "Invalid key";
	case invalidsig =>
		return "Invalid sig";
	};
};
