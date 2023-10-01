// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fs;
use io;
use memio;
use net::ip;
use os;
use strings;

// Represents a host line in /etc/hosts, guaranteed to have at least a single
// name. The first name is the canonical one.
export type host = struct {
	addr: ip::addr,
	names: []str,
};

// Iterator through the host lines in a host file.
export type iterator = struct {
	handle: io::handle,
};

// Returned when an invalid host line was found.
export type invalid = !void;

// All possible errors returned from this module.
export type error = !(io::error | invalid | utf8::invalid | ip::invalid
	| fs::error);

// Converts an [[error]] to a human-friendly representation.
export fn strerror(err: error) const str = match (err) {
case invalid =>
	return "Host file format is invalid";
case utf8::invalid =>
	return "File is invalid UTF-8";
case ip::invalid =>
	return "IP address is invalid";
case let err: io::error =>
	return io::strerror(err);
case let err: fs::error =>
	return fs::strerror(err);
};

// Creates an [[iterator]] for a provided [[io::handle]] pointing to
// the /etc/hosts file. The user should call [[next]] to iterate through
// host lines.
export fn iter(in: io::handle) iterator = iterator {
	handle = in,
};

// Returns the next host line as a [[host]] type.
export fn next(it: *iterator) (host | void | error) = for (true) {
	const line = match (bufio::read_line(it.handle)) {
	case io::EOF =>
		return void;
	case let line: []u8 =>
		yield line;
	};
	defer free(line);
	if (len(line) == 0 || line[0] == '#') {
		continue;
	};

	const scanner = memio::fixed(line);
	const tok = match (bufio::read_tok(&scanner, ' ', '\t')?) {
	case io::EOF =>
		return void;
	case let tok: []u8 =>
		yield tok;
	};
	defer free(tok);
	const addr = ip::parse(strings::fromutf8(tok)?)?;

	let names: []str = [];
	for (true) {
		const tok = match (bufio::read_tok(&scanner, ' ', '\t')?) {
		case io::EOF =>
			break;
		case let tok: []u8 =>
			yield tok;
		};
		if (len(tok) == 0) continue;

		append(names, strings::fromutf8(tok)?);
	};
	if (len(names) == 0) {
		return invalid;
	};

	return host {
		addr = addr,
		names = names,
	};
};

// Looks up a slice of addresses from /etc/hosts.
export fn lookup(name: const str) ([]ip::addr | error) = {
	const file = os::open(PATH)?;
	defer io::close(file)!;
	let it = iter(file);
	return iter_lookup(&it, name);
};

// Looks up a slice of addresses given an [[iterator]] to /etc/hosts.
export fn iter_lookup(it: *iterator, name: const str) ([]ip::addr | error) = {
	let addrs: []ip::addr = [];
	for (true) match(next(it)?) {
	case void => break;
	case let h: host =>
		defer finish(h);
		for (let i = 0z; i < len(h.names); i += 1) {
			if (h.names[i] == name) {
				append(addrs, h.addr);
			};
		};
	};
	return addrs;
};

// Frees resources associated with a [[host]].
export fn finish(host: host) void = {
	for (let i = 0z; i < len(host.names); i += 1) {
		free(host.names[i]);
	};
	free(host.names);
};
