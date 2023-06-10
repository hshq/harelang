// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Kiëd Llaentenn <kiedtl@tilde.team>
use errors;
use fs;
use io;
use os;

// Returns a stream connected to the TTY of the current process. The caller must
// close it using [[io::close]].
export fn open() (io::file | error) = {
	match (os::open("/dev/tty", fs::flag::RDWR)) {
	case let f: io::file =>
		return f;
	case fs::error =>
		return errors::noentry;
	};
};
