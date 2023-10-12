// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net;
use net::dial;

fn dial_unix(addr: str, service: str) (net::socket | dial::error) = {
	match (connect(addr)) {
	case let conn: net::socket =>
		return conn;
	case let err: net::error =>
		return err;
	};
};

@init fn registerproto() void = {
	dial::registerproto("unix", &dial_unix);
};
