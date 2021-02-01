use io;
use os;

export fn main() void = {
	let in = os::stdin;
	if (len(os::args) > 1z) {
		in = match (os::open(os::args[1], io::mode::RDONLY)) {
			stream: *io::stream => stream,
			err: io::error => {
				io::errorln(io::errstr(err));
				os::exit(1);
			},
		};
	};

	let buf: [1024]u8 = [0u8...];
	for (true) {
		match (io::read(in, buf[..])) {
			err: io::error => match (err) {
				err: io::closed => break,
				* => abort(),
			},
			n: size => io::write(os::stdout, buf[..n]),
		};
	};
};
