// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use net::ip;
use strconv;
use strings;

export type reader = struct {
	scan: bufio::scanner,

	// Only one of these is valid at a time (return values from [[next]] are
	// borrowed from this).
	union {
		addr_list: []ip::addr,
		subnet_list: []ip::subnet,
		str_list: []str,
	},

	options: options,
};

// Reads an /etc/resolv.conf-formatted file from the provided I/O handle. Use
// [[next]] to enumerate directives from the file and pass the return value to
// [[finish]] to free resources associated with the reader.
export fn read(in: io::handle) reader = {
	return reader {
		scan = bufio::newscanner(in),
		...
	};
};

// Frees resources associated with a [[reader]].
export fn finish(rd: *reader) void = {
	bufio::finish(&rd.scan);
	free(rd.addr_list);
};

// Reads the next [[parameter]] from a resolv.conf [[reader]]. The return value
// is borrowed from the [[reader]].
export fn next(rd: *reader) (parameter | io::EOF | error) = {
	for (const line => bufio::scan_line(&rd.scan)?) {
		if (strings::hasprefix(line, '#') || strings::hasprefix(line, ';')) {
			continue;
		};
		if (len(line) == 0) {
			continue;
		};

		const tok = strings::tokenize(line, " \t");

		const name = match (strings::next_token(&tok)) {
		case let name: str =>
			yield name;
		case done =>
			continue;
		};

		const val = switch (name) {
		case "nameserver" =>
			yield parse_addr(rd, &tok)?;
		case "search" =>
			yield parse_str_list(rd, &tok)?;
		case "sortlist" =>
			yield parse_subnet_list(rd, &tok)?;
		case "options" =>
			yield parse_options(rd, &tok)?;
		case =>
			continue;
		};

		return parameter {
			name = name,
			value = val,
		};
	};

	return io::EOF;
};

fn parse_addr(rd: *reader, tok: *strings::tokenizer) (value | error) = {
	const addr = match (strings::next_token(tok)) {
	case let addr: str =>
		yield addr;
	case done =>
		return invalid;
	};

	return ip::parse(addr)?;
};

fn parse_subnet_list(rd: *reader, tok: *strings::tokenizer) (value | error) = {
	rd.subnet_list = rd.subnet_list[..0];

	for (const tok => strings::next_token(tok)) {
		if (len(tok) == 0) {
			continue;
		};

		const subnet = ip::parsecidr(tok)?;
		append(rd.subnet_list, subnet);
	};

	return rd.subnet_list;
};

fn parse_str_list(rd: *reader, tok: *strings::tokenizer) (value | error) = {
	rd.str_list = rd.str_list[..0];

	for (const tok => strings::next_token(tok)) {
		if (len(tok) == 0) {
			continue;
		};
		append(rd.str_list, tok);
	};

	return rd.str_list;
};

fn parse_options(rd: *reader, tok: *strings::tokenizer) (value | error) = {
	rd.options = DEFAULT_OPTIONS;
	let opts = &rd.options;

	for (const tok => strings::next_token(tok)) {
		if (len(tok) == 0) {
			continue;
		};

		const (name, val) = strings::cut(tok, ":");
		switch (name) {
		case "debug" =>
			opts.debug = true;
		case "ndots" =>
			match (strconv::stou(val)) {
			case let u: uint =>
				opts.ndots = u;
			case =>
				return invalid;
			};
		case "timeout" =>
			match (strconv::stou(val)) {
			case let u: uint =>
				opts.timeout = u;
			case =>
				return invalid;
			};
		case "attempts" =>
			match (strconv::stou(val)) {
			case let u: uint =>
				opts.attempts = u;
			case =>
				return invalid;
			};
		case "rotate" =>
			opts.rotate = true;
		case "no-aaaa" =>
			opts.no_aaaa = true;
		case "no-check-names" =>
			opts.no_check_names = true;
		case "inet6" =>
			opts.inet6 = true;
		case "edns0" =>
			opts.edns0 = true;
		case "single-request" =>
			opts.single_request = true;
		case "no-tld-query" =>
			opts.no_tld_query = true;
		case "use-vc" =>
			opts.use_vc = true;
		case "no-reload" =>
			opts.no_reload = true;
		case "trust-ad" =>
			opts.trust_ad = true;
		case => void;
		};
	};

	return opts;
};
