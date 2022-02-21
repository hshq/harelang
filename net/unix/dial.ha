// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use io;
use net::dial;
use net;

fn dial_unix(addr: str, service: str) (io::file | dial::error) = {
	match (connect(addr)) {
	case let conn: io::file =>
		return conn;
	case let err: net::error =>
		return err;
	};
};

@init fn registerproto() void = {
	dial::registerproto("unix", &dial_unix);
};
