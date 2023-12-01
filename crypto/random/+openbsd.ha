// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use io;

// Fills the given buffer with cryptographically random data. If the system is
// unable to provide random data, abort. If you need to handle errors or want to
// use whatever random data the system can provide, even if less than the
// requested amount, use [[stream]] instead.
export fn buffer(buf: []u8) void = {
	rt::arc4random_buf(buf: *[*]u8: *const opaque, len(buf));
};

fn rand_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s == stream);
	buffer(buf);
	return len(buf);
};
