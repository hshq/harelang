// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use io;
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

// Dynamic update prerequisite unsatisfied: a domain name exists when it
// shouldn't.
export type name_exists = !void;

// Dynamic update prerequisite unsatisfied: a resource record set exists when it
// shouldn't.
export type rrset_exists = !void;

// Dynamic update prerequisite unsatisfied: a resource record set doesn't exists
// when it should.
export type rrset_error = !void;

// Server not authoritative for the zone or request not authorized.
export type not_auth = !void;

// Name not contained in zone.
export type not_zone = !void;

// TSIG signature validation failed.
export type bad_sig = !void;

// Key not recognized.
export type bad_key = !void;

// Signature out of time window.
export type bad_time = !void;

// Any other server-provided error condition not known to Hare.
export type unknown_error = !u8;

// All error types which might be returned from functions in this module.
export type error = !(format | server_failure | name_error
	| not_implemented | refused | name_exists
	| rrset_exists | rrset_error | not_auth | not_zone
	| bad_sig | bad_key | bad_time | unknown_error
	| errors::invalid | errors::overflow | errors::timeout
	| net::error | io::error);

// Converts an error into a human-friendly string. The result may be statically
// allocated.
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
	case name_exists =>
		return "Dynamic update prerequisite unsatisfied: a domain name exists when it shouldn't";
	case rrset_exists =>
		return "Dynamic update prerequisite unsatisfied: a resource record set exists when it shouldn't";
	case rrset_error =>
		return "Dynamic update prerequisite unsatisfied: a resource record set doesn't exist when it should";
	case not_auth =>
		return "Server not authoritative for the zone or request not authorized";
	case not_zone =>
		return "Name not contained in zone";
	case bad_sig =>
		return "TSIG signature validation failed";
	case bad_key =>
		return "Key not recognized";
	case bad_time =>
		return "Signature out of time window";
	case let ue: unknown_error =>
		return fmt::bsprintf(buf, "Unknown DNS error {}", ue: u8);
	case errors::invalid =>
		return "The message contains one or more field with invalid values";
	case errors::overflow =>
		return "The encoded message would exceed the buffer size";
	case errors::timeout =>
		return "The DNS request timed out";
	case let err: net::error =>
		return net::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	};
};

fn check_rcode(rcode: rcode) (void | error) = {
	switch (rcode) {
	case rcode::NOERROR => void;
	case rcode::FORMERR =>
		return format;
	case rcode::SERVFAIL =>
		return server_failure;
	case rcode::NXDOMAIN =>
		return name_error;
	case rcode::NOTIMP =>
		return not_implemented;
	case rcode::REFUSED =>
		return refused;
	case rcode::YXDOMAIN =>
		return name_exists;
	case rcode::YXRRSET =>
		return rrset_exists;
	case rcode::NXRRSET =>
		return rrset_error;
	case rcode::NOTAUTH =>
		return not_auth;
	case rcode::NOTZONE =>
		return not_zone;
	case rcode::BADSIG =>
		return bad_sig;
	case rcode::BADKEY =>
		return bad_key;
	case rcode::BADTIME =>
		return bad_time;
	case =>
		return rcode: unknown_error;
	};
};
