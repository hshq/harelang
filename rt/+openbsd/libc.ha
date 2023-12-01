// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Miscellaneous libc functions

export @symbol("arc4random_buf") fn arc4random_buf(
	buf: *opaque,
	nbytes: size
) void;

@symbol("ptsname") fn libc_ptsname(flides: int) *u8;

export fn ptsname(flides: int) (*u8 | errno) = {
	let res = libc_ptsname(flides);

	if (res == null) {
		return *__errno(): errno;
	};
	return res;
};
