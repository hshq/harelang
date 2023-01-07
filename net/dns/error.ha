// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use errors;
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
export type error = !(format | server_failure | name_error
	| not_implemented | refused | unknown_error
	| errors::overflow | errors::timeout | net::error);

export fn strerror(err: error) const str = {
	static let buf: [64]u8 = [0...];
	match (err) {
	case format =>
		return "The DNS message was poorly formatted";
	case server_failure =>
		return "The name server was unable to process this query due to a problem with the name server";
	case name_error =>
		return "The domain name referenced in the query does not exist";
	case not_implemented =>
		return "The name server does not support the requested kind of query";
	case refused =>
		return "The name server refuses to perform the specified operation for policy reasons";
	case let ue: unknown_error =>
		return fmt::bsprintf(buf, "Unknown DNS error {}", ue: u8);
	case errors::overflow =>
		return "The encoded message would exceed the buffer size";
	case errors::timeout =>
		return "The DNS request timed out";
	case let err: net::error =>
		return net::strerror(err);
	};
};

fn check_rcode(rcode: rcode) (void | error) = {
	switch (rcode) {
	case rcode::NO_ERROR => void;
	case rcode::FMT_ERROR =>
		return format;
	case rcode::SERVER_FAILURE =>
		return server_failure;
	case rcode::NAME_ERROR =>
		return name_error;
	case rcode::NOT_IMPLEMENTED =>
		return not_implemented;
	case rcode::REFUSED =>
		return refused;
	case =>
		return rcode: unknown_error;
	};
};
