// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2022 Umar Getagazov <umar@handlerug.me>
use ascii;
use encoding::utf8;
use io;
use net::ip;
use strconv;
use strings;
use strio;

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
	let buf = strio::dynamic();
	defer io::close(&buf)!;
	let host: (str | ip::addr6) = "";
	let port = 0u16;
	let userinfo = "";
	let has_userinfo = false;

	for (true) {
		const r = match (strings::next(in)) {
		case let r: rune =>
			yield r;
		case void =>
			break;
		};

		if (r == '[') {
			if (len(strio::string(&buf)) > 0) {
				if (len(userinfo) > 0) {
					return invalid;
				} else {
					userinfo = percent_decode(
						strio::string(&buf))?;
				};
			};
			strio::reset(&buf);

			for (true) {
				const r = wantrune(in)?;
				if (r == ']') {
					break;
				};
				strio::appendrune(&buf, r)!;
			};

			const addr = percent_decode(strio::string(&buf))?;
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
				userinfo = percent_decode(strio::string(&buf))?;
				strio::reset(&buf);
				has_userinfo = true;
			case '/' =>
				// This was just host
				strings::prev(in);
				host = percent_decode(strio::string(&buf))?;
				break;
			case ':' =>
				// This was host+port
				host = percent_decode(strio::string(&buf))?;
				port = parse_port(in)?;
				break;
			case =>
				return invalid;
			};
		} else {
			strio::appendrune(&buf, r)!;
		};
	};

	match (host) {
	case let s: str =>
		// In end of string case
		if (len(s) == 0) {
			host = percent_decode(strio::string(&buf))?;
		};
	case => yield;
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
			case void =>
				break;
			};
		};
	};

	for (true) {
		match (strings::next(in)) {
		case let r: rune =>
			if (r == '?' || r == '#') {
				strings::prev(in);
				break;
			};
			if (!is_pchar(r) && r != '/') {
				return invalid;
			};
		case void =>
			break;
		};
	};

	return percent_decode(strings::slice(&copy, in));
};

fn parse_query(in: *strings::iterator) (str | invalid) = {
	let copy = *in;
	for (true) {
		match (strings::next(in)) {
		case let r: rune =>
			if (r == '#') {
				strings::prev(in);
				break;
			};
			if (!is_pchar(r) && r != '/' && r != '?') {
				return invalid;
			};
		case void =>
			break;
		};
	};
	return strings::dup(strings::slice(&copy, in));
};

fn parse_fragment(in: *strings::iterator) (str | invalid) = {
	let copy = *in;
	for (true) {
		match (strings::next(in)) {
		case let r: rune =>
			if (!is_pchar(r) && r != '/' && r != '?') {
				return invalid;
			};
		case void =>
			break;
		};
	};

	return percent_decode(strings::slice(&copy, in))?;
};

fn parse_port(in: *strings::iterator) (u16 | invalid) = {
	let copy = *in;
	for (true) {
		const r = match (strings::next(in)) {
		case let r: rune =>
			yield r;
		case void =>
			break;
		};

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
	let buf = strio::dynamic();
	percent_decode_static(&buf, s)?;
	return strio::string(&buf);
};

fn percent_decode_static(out: io::handle, s: str) (void | invalid) = {
	let iter = strings::iter(s);
	let tmp = strio::dynamic();
	defer io::close(&tmp)!;
	let percent_data: []u8 = [];
	for (true) {
		match (strings::next(&iter)) {
		case let r: rune =>
			if (r == '%') {
				strio::reset(&tmp);
				for (let i = 0z; i < 2; i += 1) {
					const r = wantrune(&iter)?;
					strio::appendrune(&tmp, r)!;
				};

				match (strconv::stou8b(strio::string(&tmp),
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
						strio::concat(out, stro)!;
					case utf8::invalid =>
						return invalid;
					};

					percent_data = [];
				};

				strio::appendrune(out, r)!;
			};
		case void =>
			if(len(percent_data) > 0) {
				match(strings::fromutf8(percent_data)) {
				case let stro: str =>
					strio::concat(out, stro)!;
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
