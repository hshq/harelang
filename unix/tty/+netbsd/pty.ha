// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use io;
use os;
use rt;
use types::c;
use strings;

// Opens an available pseudoterminal and returns the file descriptors of the
// master and slave.
export fn openpty() ((io::file, io::file) | fs::error) = {
	let master = open_master()?;
	let slave = match (get_slave(master)) {
	case let e: fs::error =>
		io::close(master)!;
		return e;
	case let s: io::file =>
		yield s;
	};
	return (master, slave);
};

// Opens an available pseudoterminal master.
fn open_master() (io::file | fs::error) = {
	match (rt::posix_openpt(rt::O_RDWR | rt::O_NOCTTY)) {
	case let e: rt::errno =>
		return errors::errno(e);
	case let i: int =>
		return io::fdopen(i);
	};
};

// Returns a file descriptor referring to the pseudoterminal slave for a
// pseudoterminal master.
fn get_slave(master: io::file) (io::file | fs::error) =
	os::open(ptsname(master)?, fs::flag::RDWR);

// Returns the filename of the pseudoterminal slave.
export fn ptsname(master: io::file) (str | error) = {
	let pm = rt::ptmget { ... };
	match (rt::ioctl(master, rt::TIOCPTSNAME, &pm)) {
	case let e: rt::errno =>
		switch (e) {
		case rt::EBADF =>
			return errors::invalid;
		case rt::EINVAL, rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
	return strings::dup(c::tostr(&pm.sn: *const c::char)!);
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
