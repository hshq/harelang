// An error produced by the underlying source.
export type os_error = struct {
	string: *fn(data: *void) str,
	data: *void,
}!;

// An error indicating that the underlying stream has been closed.
export type closed = void!;

// An error indicating that the requested operation is not supported.
export type unsupported = void!;

// Any error which may be returned from an I/O function.
export type error = (os_error | closed | unsupported)!;

// Indicates an end-of-file condition.
export type EOF = void;

// Converts an I/O error into a user-friendly string.
export fn errstr(err: error) str = {
	return match (err) {
		err: os_error => err.string(err.data),
		unsupported   => "The requested operation is not supported",
		closed        => "This stream has been closed",
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
	SET = 0,
	CUR = 1,
	END = 2,
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
// the underlying resources and free everything except for the stream pointer
// itself. The other stream functions may be called after close is called; it is
// their responsibility to return [io::closed] in this case.
export type closer = fn(s: *stream) void;

// The interface for a stream which has first-class support for copying data
// from another stream. Often this only works if the second stream is of the
// same underlying stream type. This is optional, [io::copy] still works even
// with a stream which does not implement this (it falls back to calling read
// and write in a loop).
//
// Returns the number of bytes copied, or an error if one occured. Do not close
// either stream. If the operation is unsupported for this particular pair of
// streams, return [io::unsupported] to have [io::copy] proceed with its
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
