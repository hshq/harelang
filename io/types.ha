// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;

// Returned by [[readall]] if the I/O handle returned [[EOF]] prior to
// completely reading an item. Stores the amount that was succesfully read.
export type underread = !size;

// Any error which may be returned from an I/O function.
export type error = !(...errors::error | underread);

// Indicates an end-of-file condition.
export type EOF = done;

// Converts an I/O [[error]] into a user-friendly string.
export fn strerror(err: error) str = {
	match (err) {
	case underread =>
		return "Insufficient data to read entire item";
	case let err: errors::error =>
		return errors::strerror(err);
	};
};

// Used to indicate if a stream should be used for reading, or writing, or both.
export type mode = enum u8 {
	NONE	= 0,
	READ	= 1 << 0,
	WRITE	= 1 << 1,
	RDWR	= READ | WRITE,
};

// From "whence" a seek operation should occur.
export type whence = enum {
	SET = 0, // Relative to beginning (i.e. set absolute position).
	CUR = 1, // Relative to current position.
	END = 2, // Relative to end of handle.
};

// The interface for a stream which can be read from. Reads up to len(buf)
// bytes from the reader into the given buffer, returning the number of bytes
// read or an error.
export type reader = fn(s: *stream, buf: []u8) (size | EOF | error);

// The interface for a stream which can be written to. Writes up to len(buf)
// bytes to the writer from the given buffer, returning the number of bytes
// written or an error.
export type writer = fn(s: *stream, buf: const []u8) (size | error);

// The interface for a stream which can be closed. This function should close
// and free any underlying resources, and cannot be used again.
export type closer = fn(s: *stream) (void | error);

// The interface for a stream which has first-class support for copying data
// from another stream. Often this only works if the second stream is of the
// same underlying stream type. This is optional, [[copy]] still works even with
// a stream which does not implement this (it falls back to calling read and
// write in a loop).
//
// Returns the number of bytes copied, or an error if one occured. Do not close
// either stream. If the operation is unsupported for this particular pair of
// streams, return [[errors::unsupported]] to have [[copy]] proceed with its
// fallback implementation.
export type copier = fn(to: *stream, from: *stream) (size | error);

// The interface for a stream which can be seeked. Sets the offset for the next
// read or write to offset, interpreted according to whence:
// whence::SET means relative to the start of the file,
// whence::CUR means relative to the current offset, and
// whence::END means relative to the end.
//
// Returns the new offset relative to the start or an error.
export type seeker = fn(s: *stream, off: off, w: whence) (off | error);
