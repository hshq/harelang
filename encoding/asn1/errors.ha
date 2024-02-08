// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;

// Encountered invalid DER encoded data.
export type invalid = !void;

// Unexpected data format.
export type badformat = !void;

// Premature EOF.
export type truncated = !void;

// Data does not fit into the encoder buffer.
export type overflow = !void;

type asn1error = !(invalid | badformat | overflow | truncated);

// Any error within the asn1 module.
export type error = !(...io::error | ...asn1error);


// Converts an [[error]] into a user-friendly string.
export fn strerror(e: error) str = {
	match (e) {
	case invalid =>
		return "Encountered invalid DER encoded data";
	case badformat =>
		return "Unexpected data format";
	case truncated =>
		return "Premature EOF";
	case overflow =>
		return "Data does not fit into the encoder buffer";
	case let e: io::error =>
		return io::strerror(e);
	};
};

fn wrap_err(e: error) io::error = {
	match (e) {
	case let e: io::error =>
		return e;
	case let e: asn1error =>
		static assert(size(asn1error) <= size(errors::opaque_data));
		let w = errors::opaque_ { strerror = &wrap_strerror, ... };
		let ptr = &w.data: *error;
		*ptr = e;
		return w;
	};
};

fn wrap_strerror(err: *errors::opaque_data) const str = {
	let e = err: *error;
	return strerror(*e);
};

// Unwraps an [[io::error]] returned by ASN.1 readers as an [[error]].
export fn unwrap_err(e: io::error) error = {
	match (e) {
	case let e: errors::opaque_ =>
		let ptr = &e.data: *error;
		return *ptr;
	case let e: io::error =>
		return e;
	};
};
