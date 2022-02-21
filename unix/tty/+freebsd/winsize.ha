// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use io;
use os;
use rt;

// Returns the dimensions of underlying terminal for an [[io::file]].
export fn winsize(fd: io::file) (ttysize | error) = {
	let wsz = rt::winsize { ... };
	match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
	case let e: rt::errno =>
		switch (e: int) {
		case rt::EBADF =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case int =>
		return ttysize {
			rows = wsz.ws_row,
			columns = wsz.ws_col,
		};
	};
};
