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
	_: busy => "The requested resource is not available",
	_: exists => "An attempt was made to create a resource which already exists",
	_: invalid => "An function was called with an invalid combination of arguments",
	_: noaccess => "The user does not have permission to use this resource",
	_: noentry => "An entry was requested which does not exist",
	_: overflow => "The requested operation caused a numeric overflow condition",
	_: unsupported => "The requested operation is not supported",
	op: opaque => op.strerror(&op.data),
};
