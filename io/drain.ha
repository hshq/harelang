// Reads an entire stream into a []u8. The caller must free the return value.
export fn drain(in: handle) ([]u8 | error) = {
	let sink: []u8 = [];
	static let buf: [4096]u8 = [0...];
	for (true) {
		match (read(in, buf[..])?) {
		case let n: size =>
			append(sink, buf[..n]...);
		case EOF =>
			break;
		};
	};
	return sink;
};
