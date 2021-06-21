use fmt;
use net;

// The DNS message was poorly formatted.
export type format = !void;

// The name server was unable to process this query due to a problem with the
// name server.
export type server_failure = !void;

// The domain name referenced in the query does not exist. Meaningful only for
// responses from an authoritative name server.
export type name_error = !void;

// The name server does not support the requested kind of query.
export type not_implemented = !void;

// The name server refuses to perform the specified operation for policy
// reasons.
export type refused = !void;

// Any other server-provided error condition not known to Hare.
export type unknown_error = !u8;

// All error types which might be returned from [[net::dns]] functions.
export type error = (format | server_failure | name_error
	| not_implemented | refused | unknown_error
	| net::error);

export fn strerror(err: error) const str = {
	static let buf: [64]u8 = [0...];
	match (err) {
		format => "The DNS message was poorly formatted",
		server_failure => "The name server was unable to process this query due to a problem with the name server",
		name_error => "The domain name referenced in the query does not exist",
		not_implemented => "The name server does not support the requested kind of query",
		refused => "The name server refuses to perform the specified operation for policy reasons",
		ue: unknown_error => fmt::bsprintf(buf, "Unknown DNS error {}", ue: u8),
		err: net::error => net::strerror(err),
	};
};
