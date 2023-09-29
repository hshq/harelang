// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// An "opaque" error is used as a portable error type for an underlying error
// which is implementation-specific. It provides a function which can be used to
// produce a string describing the error, and a small storage area for arbitrary
// implementation-specific storage.
//
// The following example shows the usage of this type for custom errors:
//
// 	fn wraperror(err: myerror) error::opaque_ = {
// 		static assert(size(myerror) <= size(errors::opaque_data));
// 		let wrapped = errors::opaque_ { strerror = &opaque_strerror, ... };
// 		let myptr = &wrapped.data: *myerror;
// 		*myptr = err;
// 		return wrapped;
// 	};
//
// 	fn opaque_strerror(err: *errors::opaque_data) const str = {
// 		let ptr = &err: *myerr;
// 		return strerror(*ptr);
// 	};
export type opaque_ = !struct {
	strerror: *fn(op: *opaque_data) const str,
	data: opaque_data,
};

// Up to 24 bytes of arbitrary data that the opaque error type may use for
// domain-specific storage.
export type opaque_data = [24]u8;
