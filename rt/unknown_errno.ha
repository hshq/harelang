// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn unknown_errno(err: errno) str = {
	static let buf: [27]u8 = [0...];
	let ubuf: [U64_BUFSZ]u8 = [0...];
	let sl = buf[..0];

	const s = *(&"[unknown errno ": *[]u8);
	static append(sl, s...);

	if (err < 0) {
		static append(sl, '-');
		const s = u64tos(ubuf, -err: u64);
		static append(sl, *(&s: *[]u8)...);
		static append(sl, ']');
	} else {
		const s = u64tos(ubuf, err: u64);
		static append(sl, *(&s: *[]u8)...);
		static append(sl, ']');
	};

	return *(&sl: *str);
};

@test fn unknown_errno() void = {
	let err: errno = -1;
	assert(strerror(err) == "[unknown errno -1]");
	err = 0;
	assert(strerror(err) == "[unknown errno 0]");
	err = 2147483647;
	assert(strerror(err) == "[unknown errno 2147483647]");
};
