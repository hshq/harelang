use bufio;
use io;
use net::ip;
use os;
use strings;

// XXX: Different platforms may want to configure a different path
def path: str = "/etc/resolv.conf";

// Reads a list of nameservers from resolv.conf. Aborts the program if the file
// does not exist, is written in an invalid format, or if any other error
// occurs.
export fn load() []ip::addr = {
	// XXX: Would be cool if we could do this without allocating anything
	let servers: []ip::addr = [];

	const file = os::open(path)!;
	defer io::close(file);

	for (true) {
		const line = match (bufio::scanline(file)) {
			io::EOF => break,
			line: []u8 => line,
		};
		defer free(line);

		const scanner = bufio::fixed(line, io::mode::READ);
		defer io::close(scanner);

		const tok = match (bufio::scantok(scanner, ' ')!) {
			io::EOF => break,
			tok: []u8 => tok,
		};
		defer free(tok);
		if (strings::fromutf8(tok) != "nameserver") {
			continue;
		};

		const tok = match (bufio::scantok(scanner, ' ')!) {
			io::EOF => break,
			tok: []u8 => tok,
		};
		defer free(tok);
		append(servers, ip::parse(strings::fromutf8(tok))!);
	};

	return servers;
};
