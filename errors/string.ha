// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Converts an [[error]] into a human-friendly string representation.
//
// Note that this strerror implementation lacks any context-specific information
// about the error types supported. For example, [[exists]] is stringified as "An
// attempt was made to create a resource which already exists", but if source of
// the error is, say, creating a file, it would likely be more appropriate to
// use the term "file" rather than "resource". For this reason, it is preferred
// that modules which return an error type from this module provide their own
// strerror function which provides more context-appropriate error messages for
// each of those types.
export fn strerror(err: error) const str = match (err) {
case busy =>
	yield "The requested resource is not available";
case exists =>
	yield "An attempt was made to create a resource which already exists";
case invalid =>
	yield "A function was called with an invalid combination of arguments";
case noaccess =>
	yield "The user does not have permission to use this resource";
case noentry =>
	yield "An entry was requested which does not exist";
case overflow =>
	yield "The requested operation caused a numeric overflow condition";
case unsupported =>
	yield "The requested operation is not supported";
case timeout =>
	yield "The requested operation timed out";
case cancelled =>
	yield "The requested operation was cancelled";
case refused =>
	yield "A connection attempt was refused";
case nomem =>
	yield "Unable to allocate sufficient memory for the requested operation";
case interrupted =>
	yield "Operation interrupted";
case again =>
	yield "Try again";
case let op: opaque_ =>
	yield op.strerror(&op.data);
};
