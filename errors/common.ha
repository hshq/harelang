// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The requested resource is not available.
export type busy = !void;

// An attempt was made to create a resource which already exists.
export type exists = !void;

// A function was called with an invalid combination of arguments.
export type invalid = !void;

// The user does not have permission to use this resource.
export type noaccess = !void;

// An entry was requested which does not exist.
export type noentry = !void;

// The requested operation caused a numeric overflow condition.
export type overflow = !void;

// The requested operation is not supported.
export type unsupported = !void;

// The requested operation timed out.
export type timeout = !void;

// The requested operation was cancelled.
export type cancelled = !void;

// A connection attempt was refused.
export type refused = !void;

// Unable to allocate sufficient memory for the requested operation.
export type nomem = !void;

// An operation was interrupted.
export type interrupted = !void;

// The user should attempt an operation again.
export type again = !void;

// A tagged union of all error types.
export type error = !(
	busy |
	exists |
	invalid |
	noaccess |
	noentry |
	overflow |
	unsupported |
	timeout |
	cancelled |
	refused |
	nomem |
	interrupted |
	again |
	opaque_
);
