// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Kiëd Llaentenn <kiedtl@tilde.team>
use rt;
use io;
use os;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	let wsz = rt::winsize { ... };
	match (rt::ioctl(fd, rt::TIOCGWINSZ, &wsz: *void)) {
	case let e: rt::errno =>
		return false;
	case let r: int =>
		return r == 0;
	};
};
