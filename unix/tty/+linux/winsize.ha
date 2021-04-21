use errors;
use io;
use os;
use rt;

// Returns an winsize struct containing the dimensions of underlying fd of the
// stream.
export fn winsize(tty: *io::stream) (ttysize | error) = {
	let fd = match (os::streamfd(tty, true)) {
		f: int => f,
		_: void => return errors::invalid,
	};
	let wsz = rt::winsize { ... };
	return match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
		e: rt::errno => {
			switch (e: int) {
				rt::EBADFD => errors::invalid,
				rt::ENOTTY => errors::unsupported,
				* => abort("unreachable"),
			};
		},
		_: int => ttysize {
			rows    = wsz.ws_row,
			columns = wsz.ws_col,
		},
	};
};
