use net::ip;

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
