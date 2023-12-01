// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use io;
use os;
use rt;
use types::c;

// Opens an available pseudoterminal and returns the file descriptors of the
// master and slave.
export fn openpty() ((io::file, io::file) | fs::error) = {
	let master = open_master()?;
	defer io::close(master)!;

	let ptm = rt::ptmget { ... };
	match (rt::ioctl(master, rt::PTMGET, &ptm)) {
	case let e: rt::errno =>
		return errors::errno(e);
	case =>	void;
	};

	return (ptm.cfd, ptm.sfd);
};

// Opens an available pseudoterminal master.
fn open_master() (io::file | fs::error) = {
	match (rt::open(rt::PATH_PTMDEV, rt::O_RDWR, 0)) {
	case let e: rt::errno =>
		return errors::errno(e);
	case let i: int =>
		return io::fdopen(i);
	};
};

// Returns the filename of the pseudoterminal slave.
export fn ptsname(master: io::file) (str | error) = {
	static let path_buf: [rt::PATH_MAX]u8 = [0...];

	let name = match (rt::ptsname(master)) {
	case let name: *u8 =>
		yield name: *[*]u8;
	case let err: rt::errno =>
		switch (err) {
		// master is not a pseudo-terminal device
		case rt::EINVAL =>
			return errors::unsupported;
		// master is not an open valid file descriptor
		case rt::EBADF =>
			return errors::invalid;
		case =>
			abort("Unexpected error from ptsname");
		};
	};
	let namelen = c::strlen(name: *const c::char);
	path_buf[..namelen] = name[..namelen];

	return c::tostrn(&path_buf: *const c::char, namelen)!;
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = rt::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (rt::ioctl(pty, rt::TIOCSWINSZ, &wsz)) {
	case let e: rt::errno =>
		switch (e) {
		case rt::EBADF, rt::EINVAL =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
};
