// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Sets all bytes in a slice to zero. This is suitable for erasing private data
// from a slice.
export fn zero(buf: []u8) void = {
	rt::memset(buf: *[*]u8, 0, len(buf));
};
