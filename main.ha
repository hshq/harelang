use io;
use os;

export fn main() void = {
	let in = os::stdin;
	if (len(os::args) > 1z) {
		in = match (os::open(os::args[1], io::mode::RDONLY)) {
			stream: *io::stream => stream,
			err: io::error => fatal(io::errstr(err)),
		};
	};
	defer io::close(in);

	let buf: [1024]u8 = [0u8...];
	for (true) {
		match (io::read(in, buf[..])) {
			err: io::error => match (err) {
				io::closed => break,
				* => fatal(io::errstr(err)),
			},
			n: size => match (io::write(os::stdout, buf[..n])) {
				err: io::error => fatal(io::errstr(err)),
				* => void,
			},
		};
	};
};

@noreturn fn fatal(why: str) void = {
	io::errorln(why);
	os::exit(1);
};
