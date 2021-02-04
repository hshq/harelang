fn bytes_reverse(b: []u8) void = {
	if (len(b) == 0z) {
		return;
	};
	for (let s = 0z, e = len(b) - 1z; s < e) {
		let x = b[s];
		b[s] = b[e];
		b[e] = x;
		s += 1z;
		e -= 1z;
	};
};

fn ztos(u: size) const str = {
	static let buf: [21]u8 = [0u8...]; // 20 digits plus NUL
	buf = [0u8...];

	let s = struct {
		b: *[*]u8 = &buf,
		l: size = 0z,
		c: size = 0z,
	};

	if (u == 0z) {
		s.b[s.l] = '0': u32: u8;
		s.l += 1z;
	};

	for (u > 0z) {
		s.b[s.l] = '0': u32: u8 + (u % 10z): u8;
		s.l += 1z;
		u /= 10z;
	};

	bytes_reverse(s.b[..s.l]);
	s.b[s.l] = 0u8;
	return *(&s: *str);
};
