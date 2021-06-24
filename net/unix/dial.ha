use io;
use net::dial;
use net;

fn dial_unix(addr: str, service: str) (*io::stream | dial::error) = {
	return match (connect(addr)) {
		conn: *io::stream => conn,
		err: net::error => err,
	};
};

@init fn registerproto() void = {
	dial::registerproto("unix", &dial_unix);
};
