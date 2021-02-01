// Copies data from one stream into another. Note that this function will never
// return if the source stream is infinite.
export fn copy(dest: *stream, src: *stream) (error | size) = {
	let w = 0z;
	let buf: [4096]u8 = [0u8...];
	for (true) {
		match (read(src, buf[..])) {
			err: error => match (err) {
				closed => break,
				* => return err,
			},
			n: size => match (write(dest, buf[..n])) {
				err: error => return err,
				r: size => {
					assert(r == n); // TODO?
					w += n;
				},
			},
		};
	};
	return w;
};
