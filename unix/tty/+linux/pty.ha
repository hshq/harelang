// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use io;
use os;
use rt;

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
	return os::open("/dev/ptmx", fs::flag::RDWR);
};

// Returns a file descriptor referring to the pseudoterminal slave for a
// pseudoterminal master.
fn get_slave(master: io::file) (io::file | fs::error) = {
	// Unlock the pseudoterminal slave
	match (rt::ioctl(master, rt::TIOCSPTLCK, &0)) {
	case rt::errno =>
		return errors::invalid;
	case => void;
	};

	let ioctl = rt::ioctl(
		master, rt::TIOCGPTPEER,
		(rt::O_RDWR | rt::O_NOCTTY): u64);
	match (ioctl) {
	case let e: rt::errno =>
		return errors::errno(e);
	case let fd: int =>
		return io::fdopen(fd);
	};
};

// Returns the filename of the pseudoterminal slave.
export fn ptsname(master: io::file) (str | error) = {
	let pty = 0;
	match (rt::ioctl(master, rt::TIOCGPTN, &pty)) {
	case let e: rt::errno =>
		switch (e) {
		case rt::EBADF =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case =>
		static let buf: [9 + 20]u8 = [0...];
		return fmt::bsprintf(buf[..len(buf)], "/dev/pts/{}", pty);
	};
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = rt::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (rt::ioctl(pty, rt::TIOCSWINSZ, &wsz)) {
	case let e: rt::errno =>
		switch (e) {
		case rt::EBADF =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
};
