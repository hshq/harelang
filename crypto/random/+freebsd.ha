// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;

// Fills the given buffer with cryptographically random data. If the system is
// unable to provide random data, abort. If you need to handle errors or want to
// use whatever random data the system can provide, even if less than the
// requested amount, use [[stream]] instead.
export fn buffer(buf: []u8) void = {
	let n = 0z;
	for (n < len(buf)) {
		match (rt::getrandom(buf[n..]: *[*]u8, len(buf), 0)) {
		case let err: rt::errno =>
			switch (err) {
			case rt::EINTR => void;
			case =>
				abort();
			};
		case let z: size =>
			n += z;
		};
	};
};

fn rand_reader(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	assert(s == stream);
	match (rt::getrandom(buf: *[*]u8, len(buf), 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		return n;
	};
};
