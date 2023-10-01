// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net::ip;
use strings;

// Representation of a parsed URI.
export type uri = struct {
	scheme: str,

	host: (str | ip::addr),
	port: u16,
	userinfo: str,

	path: str,
	query: str,
	fragment: str,
};

// Duplicates a [[uri]].
export fn dup(u: *uri) uri = {
	return uri {
		scheme = strings::dup(u.scheme),

		host = match (u.host) {
		case let host: str =>
			yield strings::dup(host);
		case let ip: ip::addr =>
			yield ip;
		},
		port = u.port,
		userinfo = strings::dup(u.userinfo),

		path = strings::dup(u.path),
		query = strings::dup(u.query),
		fragment = strings::dup(u.fragment),
	};
};

// Frees resources associated with a [[uri]].
export fn finish(u: *uri) void = {
	free(u.scheme);
	match (u.host) {
	case let s: str =>
		free(s);
	case => void;
	};
	free(u.userinfo);
	free(u.path);
	free(u.query);
	free(u.fragment);
};
