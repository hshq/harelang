// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use encoding::utf8;
use io;
use memio;
use net::ip;
use strconv;
use strings;

// The URI provided to [[parse]] is invalid.
export type invalid = !void;

// Parses a URI string into [[uri]] structure. The return value must be freed
// using [[finish]].
export fn parse(in: str) (uri | invalid) = {
	let in = strings::iter(in);

	const scheme = parse_scheme(&in)?;

	// Determine hier-part variant
	let path = "";
	let authority: ((str | ip::addr6), u16, str) = ("", 0u16, "");
	match (strings::next(&in)) {
	case let r: rune =>
		switch (r) {
		case '/' =>
			// Either "//"+authority+path-abempty or path-absolute
			switch (wantrune(&in)?) {
			case '/' =>
				// "//" + authority + path-abempty
				authority = parse_authority(&in)?;
				match (strings::next(&in)) {
				case let r: rune =>
					switch (r) {
					case '?', '#' =>
						// path-empty
						strings::prev(&in);
					case '/' =>
						// path-absolute
						strings::prev(&in);
						path = parse_path(&in,
							path_mode::ABSOLUTE)?;
					case =>
						return invalid;
					};
				case => void; // path-empty
				};
			case =>
				// path-absolute
				strings::prev(&in);
				path = parse_path(&in, path_mode::ABSOLUTE)?;
			};
		case =>
			// path-rootless
			strings::prev(&in);
			path = parse_path(&in, path_mode::ROOTLESS)?;
		};
	case => void; // path-empty
	};

	let query = "";
	match (strings::next(&in)) {
	case let r: rune =>
		if (r == '?') {
			query = parse_query(&in)?;
		} else {
			strings::prev(&in);
		};
	case => void;
	};

	let fragment = "";
	match (strings::next(&in)) {
	case let r: rune =>
		if (r == '#') {
			fragment = parse_fragment(&in)?;
		} else {
			strings::prev(&in);
		};
	case => void;
	};

	return uri {
		scheme = scheme,

		host = match (authority.0) {
		case let ip: ip::addr6 =>
			yield ip;
		case let s: str =>
			yield match (ip::parse(s)) {
			case let a: ip::addr =>
				yield a;
			case ip::invalid =>
				yield s;
			};
		},
		port = authority.1,
		userinfo = authority.2,

		path = path,
		query = query,
		fragment = fragment,
	};
};

fn parse_scheme(in: *strings::iterator) (str | invalid) = {
	let copy = *in;
	for (let i = 0z; true; i += 1) {
		const r = wantrune(in)?;
		if (i > 0 && r == ':') {
			strings::prev(in);
			break;
		};
		if (i == 0) {
			if (!ascii::isalpha(r)) {
				return invalid;
			};
		} else {
			if (!ascii::isalnum(r) && !strings::contains("+-.", r)) {
				return invalid;
			};
		};
	};
	let s = strings::dup(strings::slice(&copy, in));
	strings::next(in);
	return s;
};

fn parse_authority(
	in: *strings::iterator,
) (((str | ip::addr6), u16, str) | invalid) = {
	// Scan everything until '@' or ':' or '/', then decide what it is
	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let host: (str | ip::addr6) = "";
	let port = 0u16;
	let userinfo = "";
	let has_userinfo = false;

	for (let r => strings::next(in)) {
		if (r == '[') {
			if (len(memio::string(&buf)!) > 0) {
				if (len(userinfo) > 0) {
					return invalid;
				} else {
					userinfo = percent_decode(
						memio::string(&buf)!)?;
				};
			};
			memio::reset(&buf);

			for (true) {
				const r = wantrune(in)?;
				if (r == ']') {
					break;
				};
				memio::appendrune(&buf, r)!;
			};

			const addr = percent_decode(memio::string(&buf)!)?;
			match (ip::parse(addr)) {
			case let v6: ip::addr6 =>
				host = v6;
			case =>
				return invalid;
			};
		} else if (r == ':' || !is_userinfo(r) && !is_host(r)) {
			switch (r) {
			case '@' =>
				if (has_userinfo) {
					return invalid;
				};
				// This was userinfo+host[+port]
				userinfo = percent_decode(memio::string(&buf)!)?;
				memio::reset(&buf);
				has_userinfo = true;
			case '/' =>
				// This was just host
				strings::prev(in);
				host = percent_decode(memio::string(&buf)!)?;
				break;
			case ':' =>
				// This was host+port
				host = percent_decode(memio::string(&buf)!)?;
				port = parse_port(in)?;
				break;
			case =>
				return invalid;
			};
		} else {
			memio::appendrune(&buf, r)!;
		};
	};

	match (host) {
	case let s: str =>
		// In end of string case
		if (len(s) == 0) {
			host = percent_decode(memio::string(&buf)!)?;
		};
	case => void;
	};

	return (host, port, userinfo);
};

type path_mode = enum {
	ABSOLUTE,
	ROOTLESS,
};

fn parse_path(in: *strings::iterator, mode: path_mode) (str | invalid) = {
	let copy = *in;
	// With rootless path, we need at least one segment
	if (mode == path_mode::ROOTLESS) {
		for (let i = 0z; true; i += 1) {
			match (strings::next(in)) {
			case let r: rune =>
				if (r == '?' || r == '#') {
					strings::prev(in);
					break;
				};
				if (r == '/') {
					if (i == 0) {
						return invalid;
					} else {
						break;
					};
				};
				if (!is_pchar(r)) {
					return invalid;
				};
			case done =>
				break;
			};
		};
	};

	for (let r => strings::next(in)) {
		if (r == '?' || r == '#') {
			strings::prev(in);
			break;
		};
		if (!is_pchar(r) && r != '/') {
			return invalid;
		};
	};

	return percent_decode(strings::slice(&copy, in));
};

fn parse_query(in: *strings::iterator) (str | invalid) = {
	let copy = *in;
	for (let r => strings::next(in)) {
		if (r == '#') {
			strings::prev(in);
			break;
		};
		if (!is_pchar(r) && r != '/' && r != '?') {
			return invalid;
		};
	};
	return strings::dup(strings::slice(&copy, in));
};

fn parse_fragment(in: *strings::iterator) (str | invalid) = {
	let copy = *in;
	for (let r => strings::next(in)) {
		if (!is_pchar(r) && r != '/' && r != '?') {
			return invalid;
		};
	};

	return percent_decode(strings::slice(&copy, in))?;
};

fn parse_port(in: *strings::iterator) (u16 | invalid) = {
	let copy = *in;
	for (let r => strings::next(in)) {
		if (!ascii::isdigit(r)) {
			strings::prev(in);
			break;
		};
	};

	match (strconv::stou16(strings::slice(&copy, in))) {
	case let port: u16 =>
		if (port == 0) {
			// There's no port 0
			return invalid;
		};
		return port;
	case =>
		return invalid;
	};
};

fn percent_decode(s: str) (str | invalid) = {
	let buf = memio::dynamic();
	percent_decode_static(&buf, s)?;
	return memio::string(&buf)!;
};

fn percent_decode_static(out: io::handle, s: str) (void | invalid) = {
	let iter = strings::iter(s);
	let tmp = memio::dynamic();
	defer io::close(&tmp)!;
	let percent_data: []u8 = [];
	for (true) {
		match (strings::next(&iter)) {
		case let r: rune =>
			if (r == '%') {
				memio::reset(&tmp);
				for (let i = 0z; i < 2; i += 1) {
					const r = wantrune(&iter)?;
					memio::appendrune(&tmp, r)!;
				};

				match (strconv::stou8(memio::string(&tmp)!,
					strconv::base::HEX)) {
				case let ord: u8 =>
					append(percent_data, ord);
				case =>
					return invalid;
				};
			} else {
				if(len(percent_data) > 0) {
					match(strings::fromutf8(percent_data)) {
					case let stro: str =>
						memio::concat(out, stro)!;
					case utf8::invalid =>
						return invalid;
					};

					percent_data = [];
				};

				memio::appendrune(out, r)!;
			};
		case done =>
			if(len(percent_data) > 0) {
				match(strings::fromutf8(percent_data)) {
				case let stro: str =>
					memio::concat(out, stro)!;
				case utf8::invalid =>
					return invalid;
				};

				percent_data = [];
			};

			break;
		};
	};
};

fn wantrune(iter: *strings::iterator) (rune | invalid) = {
	match (strings::next(iter)) {
	case let r: rune =>
		return r;
	case =>
		return invalid;
	};
};

fn is_userinfo(r: rune) bool =
	// unreserved + sub-delim + ":"
	ascii::isalnum(r) || strings::contains("-._~!$&'()*+,;=:", r)
	// %-encoded
	|| r == '%' || ascii::isxdigit(r);

fn is_host(r: rune) bool =
	// unreserved + sub-delim
	ascii::isalnum(r) || strings::contains("-._~!$&'()*+,;=", r)
	// %-encoded
	|| r == '%' || ascii::isxdigit(r);

fn is_pchar(r: rune) bool =
	// unreserved + sub-delim + ":"/"@"
	ascii::isalnum(r) || strings::contains("-._~!$&'()*+,;=:@", r)
	// %-encoded
	|| r == '%' || ascii::isxdigit(r);
