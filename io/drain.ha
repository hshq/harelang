// Reads an entire stream into a []u8.
export fn drain(in: *io::stream) ([]u8 | io::error) = {
	let sink: []u8 = [];
	static let buf: [4096]u8 = [0...];
	for (true) {
		match (read(in, buf[..])?) {
			n: size => append(sink, buf[..n]...),
			_: EOF => break,
		};
	};
	return sink;
};
