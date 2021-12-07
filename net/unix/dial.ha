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
