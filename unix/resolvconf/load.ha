// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use io;
use net::ip;
use os;
use strings;

// XXX: Different platforms may want to configure a different path
def path: str = "/etc/resolv.conf";

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

	const file = os::open(path)!;
	defer io::close(file);

	for (true) {
		const line = match (bufio::scanline(file)) {
		case io::EOF =>
			break;
		case let line: []u8 =>
			yield line;
		};
		defer free(line);
		if (len(line) == 0 || line[0] == '#': u32: u8) {
			continue;
		};

		const scanner = bufio::fixed(line, io::mode::READ);
		const tok = match (bufio::scantok(&scanner, ' ', '\t')!) {
		case io::EOF =>
			break;
		case let tok: []u8 =>
			yield tok;
		};
		defer free(tok);
		if (strings::fromutf8(tok) != "nameserver") {
			continue;
		};

		const tok = match (bufio::scantok(&scanner, ' ')!) {
		case io::EOF =>
			break;
		case let tok: []u8 =>
			yield tok;
		};
		defer free(tok);
		append(cache, ip::parse(strings::fromutf8(tok))!);
	};

	return cache;
};
