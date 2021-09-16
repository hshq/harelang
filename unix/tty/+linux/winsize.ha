use errors;
use io;
use os;
use rt;

// Returns the dimensions of underlying terminal of the stream.
export fn winsize(tty: *io::stream) (ttysize | error) = {
	let fd = match (io::unwrapfd(tty)) {
	case void =>
		return errors::unsupported;
	case fd: int =>
		yield fd;
	};
	let wsz = rt::winsize { ... };
	match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
	case e: rt::errno =>
		switch (e: int) {
		case rt::EBADFD =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case int =>
		return ttysize {
			rows    = wsz.ws_row,
			columns = wsz.ws_col,
		};
	};
};
