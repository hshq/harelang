// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use encoding::utf8;
use fmt;
use io;
use memio;
use net::ip;
use strconv;
use strings;


// Extract from RFC3986 ABNF
// URI        = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
// reg-name   = *( unreserved / pct-encoded / sub-delims )
// host       = IP-literal / IPv4address / reg-name
// pchar      = unreserved / pct-encoded / sub-delims / ":" / "@"
// query      = *( pchar / "/" / "?" )
// fragment   = *( pchar / "/" / "?" )

def unres_host: str = "-._~!$&'()*+,;=";
def unres_query_frag: str = "-._~!$&'()*+,;=:@/?";
def unres_path: str = "-._~!$&'()*+,;=:@/";

// Writes a formatted [[uri]] to an [[io::handle]]. Returns the number of bytes
// written.
export fn fmt(out: io::handle, u: *const uri) (size | io::error) = {
	let n = 0z;
	let slashes_w = false;
	let has_host = false;
	if (u.scheme != "") {
		n += fmt::fprintf(out, "{}:", u.scheme)?;
	};
	if (len(u.userinfo) > 0) {
		assert(!(u.host is str) || len(u.host as str) > 0);
		n += fmt::fprintf(out, "//{}@", u.userinfo)?;
		slashes_w = true;
	};
	match (u.host) {
	case let host: str =>
		// file scheme is allowed an empty host
		if (len(host) > 0 || u.scheme == "file") {
			has_host = true;
			if (!slashes_w) {
				n += fmt::fprint(out, "//")?;
			};
			let unres = if(u.scheme == "file") {
				yield unres_path;
			} else {
				yield unres_host;
			};
			n += percent_encode(out, host, unres)?;
		};
	case let addr: ip::addr =>
		has_host = true;
		if (!slashes_w) {
			n += fmt::fprint(out, "//")?;
		};
		n += fmtaddr(out, addr)?;
	};
	if (u.port != 0) {
		n += fmt::fprintf(out, ":{}", u.port)?;
	};
	if (has_host && len(u.path) > 0 && !strings::hasprefix(u.path, '/')) {
		n += fmt::fprint(out, "/")?;
	};
	n += percent_encode(out, u.path, unres_path)?;
	if (len(u.query) > 0) {
		// Always percent-encoded, see parse and encodequery/decodequery
		n += fmt::fprintf(out, "?{}", u.query)?;
	};
	if (len(u.fragment) > 0) {
		n += fmt::fprint(out, "#")?;
		n += percent_encode(out, u.fragment, unres_query_frag)?;
	};

	return n;
};

fn fmtaddr(out: io::handle, addr: ip::addr) (size | io::error) = {
	let n = 0z;
	match (addr) {
	case let addr: ip::addr4 =>
		n += ip::fmt(out, addr)?;
	case let addr: ip::addr6 =>
		n += fmt::fprintf(out, "[")?;
		n += ip::fmt(out, addr)?;
		n += fmt::fprintf(out, "]")?;
	};
	return n;
};

fn percent_encode(out: io::handle, src: str, allowed: str) (size | io::error) = {
	let iter = strings::iter(src);
	let n = 0z;
	for (let r => strings::next(&iter)) {
		if (ascii::isalnum(r) || strings::contains(allowed, r)) {
			n += fmt::fprint(out, r)?;
		} else {
			const en = utf8::encoderune(r);
			for (let elem .. en) {
				n += fmt::fprintf(out, "%{:X}", elem)?;
			};
		};
	};
	return n;
};

// Formats a [[uri]] into a string. The result must be freed by the caller.
export fn string(u: *const uri) str = {
	const st = memio::dynamic();
	fmt(&st, u)!;
	return memio::string(&st)!;
};
