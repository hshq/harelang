// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use rt;

// A thin wrapper around socketpair(2) that presumes [[rt::AF_UNIX]] for the
// domain and returns an unnamed pair of sockets of type [[rt::SOCK_STREAM]].
export fn socketpair(flags: net::sockflag = 0) ((net::socket, net::socket) | net::error) = {
	let sv: [2]int = [0...];
	flags ^= rt::SOCK_CLOEXEC: net::sockflag; // invert CLOEXEC
	match (rt::socketpair(rt::AF_UNIX: int, rt::SOCK_STREAM | flags, 0, &sv)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case =>
		return (io::fdopen(sv[0]), io::fdopen(sv[1]));
	};
};
