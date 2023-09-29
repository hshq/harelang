// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use memio;
use net::ip;
use os;
use strings;

let cache: []ip::addr = [];

@fini fn fini() void = {
	free(cache);
};

// Reads a list of nameservers from resolv.conf. Aborts the program if the file
// does not exist, is written in an invalid format, or if any other error
// occurs.
export fn load() []ip::addr = {
	// XXX: Would be cool if we could do this without allocating anything
	if (len(cache) != 0) {
		return cache;
	};

	const file = os::open(PATH)!;
	defer io::close(file)!;

	for (true) {
		const line = match (bufio::read_line(file)) {
		case io::EOF =>
			break;
		case let line: []u8 =>
			yield line;
		};
		defer free(line);
		if (len(line) == 0 || line[0] == '#') {
			continue;
		};

		const scanner = memio::fixed(line);
		const tok = match (bufio::read_tok(&scanner, ' ', '\t')!) {
		case io::EOF =>
			break;
		case let tok: []u8 =>
			yield tok;
		};
		defer free(tok);
		if (strings::fromutf8(tok)! != "nameserver") {
			continue;
		};

		const tok = match (bufio::read_tok(&scanner, ' ')!) {
		case io::EOF =>
			break;
		case let tok: []u8 =>
			yield tok;
		};
		defer free(tok);
		append(cache, ip::parse(strings::fromutf8(tok)!)!);
	};

	return cache;
};
