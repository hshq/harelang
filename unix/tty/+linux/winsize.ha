use errors;
use io;
use os;
use rt;

// Returns the dimensions of underlying terminal of the stream.
export fn winsize(tty: *io::stream) (ttysize | error) = {
	let fd = match (io::unwrapfd(tty)) {
		void => return errors::unsupported,
		fd: int => fd,
	};
	let wsz = rt::winsize { ... };
	return match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
		e: rt::errno => switch (e: int) {
			rt::EBADFD => errors::invalid,
			rt::ENOTTY => errors::unsupported,
			* => abort("unreachable"),
		},
		int => ttysize {
			rows    = wsz.ws_row,
			columns = wsz.ws_col,
		},
	};
};
