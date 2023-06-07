// License: MPL-2.0
// (c) 2022 Re Elbertson <citrons@mondecitronne.com>
use errors;
use fmt;
use fs;
use io;
use os;
use rt;
use types::c;

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
	os::open(ptsname(master)?, fs::flags::RDWR);

// Returns the filename of the pseudoterminal slave.
export fn ptsname(master: io::file) (str | error) = {
	// Ensure that the file descriptor refers to a master
	match (rt::ioctl(master, rt::TIOCPTMASTER, null)) {
	case let e: rt::errno =>
		if (e == rt::EBADF) return errors::invalid
		else return errors::unsupported;
	case => void;
	};

	let name: [rt::PATH_MAX]u8 = [0...];
	let fiodgname_arg = (len(name), &name);
	match (rt::ioctl(master, rt::FIODGNAME, &fiodgname_arg)) {
	case let e: rt::errno =>
		switch (e: int) {
		case rt::EBADF =>
			return errors::invalid;
		case rt::EINVAL, rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case =>
		static let path_buf: [rt::PATH_MAX]u8 = [0...];
		return fmt::bsprintf(path_buf,
			"/dev/{}", c::tostr(&name: *const c::char)!);
	};
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = rt::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (rt::ioctl(pty, rt::TIOCSWINSZ, &wsz)) {
	case let e: rt::errno =>
		switch (e: int) {
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
