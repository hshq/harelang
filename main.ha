use io;
use os;

export fn main() void = {
	let buf: [1024]u8 = [0u8...];
	for (true) {
		match (io::read(os::stdin, buf[..])) {
			err: io::error => match (err) {
				err: io::closed => break,
				* => abort(),
			},
			n: size => io::write(os::stdout, buf[..n]),
		};
	};
};
