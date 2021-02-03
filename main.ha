use io;
use os;

export fn main() void = {
	if (len(os::args) == 1z) {
		match (io::copy(os::stdout, os::stdin)) {
			err: io::error => fatal(io::errstr(err)),
			size => void,
		};
		return;
	};

	for (let i = 1z; i < len(os::args); i += 1z) {
		let in: *io::stream = match (os::open(os::args[i], io::mode::RDONLY)) {
			stream: *io::stream => stream,
			err: io::error => fatal(io::errstr(err)),
		};
		defer io::close(in);

		match (io::copy(os::stdout, in)) {
			err: io::error => fatal(io::errstr(err)),
			size => void,
		};
	};
};

@noreturn fn fatal(why: str) void = {
	io::errorln(why);
	os::exit(1);
};
