// License: MPL-2.0
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use rt;
use io;
use net;
use errors;
use io;

// A thin wrapper around socketpair(2) that presumes [[rt::AF_UNIX]] for the
// domain and returns an unnamed pair of sockets of type [[rt::SOCK_STREAM]].
export fn socketpair() ((io::file, io::file) | net::error) = {
	let sv: [2]int = [0...];
	match (rt::socketpair(rt::AF_UNIX : int, (rt::SOCK_STREAM | rt::SOCK_CLOEXEC) : int, 0, &sv)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case =>
		return (io::fdopen(sv[0]), io::fdopen(sv[1]));
	};
};

