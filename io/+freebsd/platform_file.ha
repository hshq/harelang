// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On FreeBSD, [[file]] is a file descriptor.
export type file = int;

// Opens a Unix file descriptor as a file. This is a low-level interface, to
// open files most programs will use something like [[os::open]]. This function
// is not portable.
export fn fdopen(fd: int) file = fd;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	match (rt::read(fd, buf: *[*]u8, len(buf))) {
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

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	match (rt::write(fd, buf: *const [*]u8, len(buf))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		return n;
	};
};

fn fd_close(fd: file) (void | error) = {
	match (rt::close(fd)) {
	case void => void;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	match (rt::lseek(fd, offs: i64, whence: int)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: i64 =>
		return n: off;
	};
};

fn fd_copy(to: file, from: file) (size | error) = errors::unsupported;

fn fd_lock(fd: file, flags: int) (bool | error) = {
	match (rt::flock(fd: int, flags)) {
	case void => return true;
	case let e: rt::errno =>
		if (e == rt::EWOULDBLOCK: rt::errno) {
			return false;
		} else {
			return errors::errno(e);
		};
	};
};

fn fd_trunc(fd: file, ln: size) (void | error) = {
	match (rt::ftruncate(fd: int, ln: rt::off_t)) {
	case void => void;
	case let e: rt::errno => return errors::errno(e);
	};
};
