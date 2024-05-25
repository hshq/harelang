// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

def U64_BUFSZ = 20;

fn u64tos(buf: []u8, u: u64) str = {
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
	return *(&sl: *str);
};
