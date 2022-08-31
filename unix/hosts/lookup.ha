// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use io;
use net::ip;
use os;
use strings;

// Looks up a host from /etc/hosts. Aborts the program if the file does not
// exist, is written in an invalid format, or if any other error occurs.
export fn lookup(name: str) []ip::addr = {
	// XXX: Would be cool if we could do this without allocating anything
	// XXX: Would be cool to have meaningful error handling(?)
	const file = os::open(PATH)!;
	defer io::close(file)!;
	return lookupio(name, file);
};

fn lookupio(name: str, src: io::handle) []ip::addr = {
	let buffer: [os::BUFSIZ]u8 = [0...];
	const buf = bufio::buffered(src, buffer, []);

	let addrs: []ip::addr = [];
	for (true) {
		const line = match (bufio::scanline(&buf)) {
		case io::EOF =>
			break;
		case let line: []u8 =>
			yield line;
		};
		defer free(line);
		if (len(line) == 0 || line[0] == '#') {
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
		const addr = ip::parse(strings::fromutf8(tok))!;

		for (true) {
			const tok = match (bufio::scantok(&scanner, ' ', '\t')!) {
			case io::EOF =>
				break;
			case let tok: []u8 =>
				yield tok;
			};
			defer free(tok);

			if (strings::fromutf8(tok) == name) {
				append(addrs, addr);
			};
		};
	};
	return addrs;
};

@test fn lookup() void = {
	let buf = bufio::fixed(strings::toutf8(
		"127.0.0.1	localhost\n"
		"\n"
		"# The following lines are desirable for IPv6 capable hosts\n"
		"::1     ip6-localhost ip6-loopback\n"
		"fe00::0 ip6-localnet\n"
		"ff00::0 ip6-mcastprefix\n"
		"ff02::1 ip6-allnodes\n"
		"ff02::2 ip6-allrouters\n"), io::mode::READ);
	const ips = lookupio("localhost", &buf);
	assert(len(ips) == 1);
	const got = ips[0];
	const want: ip::addr4 = [127, 0, 0, 1];
	assert(ip::equal(got, want));
};
