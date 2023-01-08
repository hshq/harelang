// License: MPL-2.0
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

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
