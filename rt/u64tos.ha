// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn u64tos(u: u64) (*[*]const u8, size) = {
	static let buf: [20]u8 = [0...]; // len("18446744073709551615")
	let sl = buf[..0];
	if (u == 0) {
		static append(sl, '0');
	};
	for (u > 0) {
		static append(sl, (u % 10): u8 + '0');
		u /= 10;
	};
	for (let s = 0z, e = len(sl) - 1; s < e) {
		let tmp = sl[s];
		sl[s] = sl[e];
		sl[e] = tmp;
		s += 1;
		e -= 1;
	};
	return (sl: *[*]const u8, len(sl));
};
