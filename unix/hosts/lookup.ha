use bufio;
use io;
use net::ip;
use os;
use strings;

// XXX: Different platforms may want to configure a different path
def path: str = "/etc/hosts";

// Looks up a host from /etc/hosts. Aborts the program if the file does not
// exist, is written in an invalid format, or if any other error occurs.
export fn lookup(name: str) (ip::addr | void) = {
	// XXX: Would be cool if we could do this without allocating anything
	// XXX: Would be cool to add caching
	const file = os::open(path)!;
	defer io::close(file);

	for (true) {
		const line = match (bufio::scanline(file)) {
			io::EOF => break,
			line: []u8 => line,
		};
		defer free(line);
		if (line[0] == '#': u32: u8) {
			continue;
		};

		const scanner = bufio::fixed(line, io::mode::READ);
		defer io::close(scanner);

		const tok = match (bufio::scantok(scanner, ' ', '\t')!) {
			io::EOF => break,
			tok: []u8 => tok,
		};
		defer free(tok);
		const addr = ip::parse(strings::fromutf8(tok))!;

		for (true) {
			const tok = match (bufio::scantok(scanner, ' ', '\t')!) {
				io::EOF => break,
				tok: []u8 => tok,
			};
			defer free(tok);

			if (strings::fromutf8(tok) == name) {
				return addr;
			};
		};
	};
};
