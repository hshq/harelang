// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;
use types;

export type vector = rt::iovec;

// Creates a vector for use with [[writev]] and [[readv]].
export fn mkvector(buf: []u8) vector = vector {
	iov_base = buf: *[*]u8,
	iov_len = len(buf),
};

// Performs a vectored read on the given file. A read is performed on each of
// the vectors, prepared with [[mkvector]], in order, and the total number of
// bytes read is returned.
export fn readv(fd: file, vectors: vector...) (size | EOF | error) = {
	if (len(vectors) > types::INT_MAX: size) {
		return errors::invalid;
	};
	match (rt::readv(fd, vectors: *[*]rt::iovec, len(vectors): int)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		switch (n) {
		case 0 =>
			return EOF;
		case =>
			return n;
		};
	};
};

// Performs a vectored write on the given file. Each of the vectors, prepared
// with [[mkvector]], are written to the file in order, and the total number of
// bytes written is returned.
export fn writev(fd: file, vectors: vector...) (size | error) = {
	if (len(vectors) > types::INT_MAX: size) {
		return errors::invalid;
	};
	match (rt::writev(fd, vectors: *[*]rt::iovec, len(vectors): int)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		return n;
	};
};
