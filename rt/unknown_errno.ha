// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn unknown_errno(err: errno) str = {
	static let buf: [27]u8 = [0...];
	const s = *(&"[unknown errno ": *[]u8);
	buf[..len(s)] = s;
	if (err < 0) {
		buf[len(s)] = '-';
		const s2 = &u64tos(-err: u64): *string;
		buf[len(s) + 1..s2.length + len(s) + 1] = s2.data[..s2.length];
		buf[s2.length + len(s) + 1] = ']';
		return *(&buf[..s2.length + len(s) + 2]: *str);
	} else {
		const s2 = &u64tos(err: u64): *string;
		buf[len(s)..s2.length + len(s)] = s2.data[..s2.length];
		buf[s2.length + len(s)] = ']';
		return *(&buf[..s2.length + len(s) + 1]: *str);
	};
};

@test fn unknown_errno() void = {
	let err: errno = -1;
	assert(strerror(err) == "[unknown errno -1]");
	err = 0;
	assert(strerror(err) == "[unknown errno 0]");
	err = 2147483647;
	assert(strerror(err) == "[unknown errno 2147483647]");
};
