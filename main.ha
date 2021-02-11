use fmt;
use io;
use os;

export fn main() void = {
	if (len(os::args) == 1z) match (io::copy(os::stdout, os::stdin)) {
		err: io::error => fmt::fatal("Error: {}", io::errstr(err)),
		size => os::exit(0),
	};

	for (let i = 1z; i < len(os::args); i += 1z) {
		let in = match (os::open(os::args[i], io::mode::RDONLY)) {
			stream: *io::stream => stream,
			err: io::error => fmt::fatal("Error: {}: {}",
				os::args[i], io::errstr(err)),
		};
		defer io::close(in);

		match (io::copy(os::stdout, in)) {
			err: io::error =>
				fmt::fatal("Error: {}", io::errstr(err)),
			size => void,
		};
	};
};
