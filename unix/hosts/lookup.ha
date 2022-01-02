use bufio;
use io;
use net::ip;
use os;
use strings;

// XXX: Different platforms may want to configure a different path
def path: str = "/etc/hosts";

// Looks up a host from /etc/hosts. Aborts the program if the file does not
// exist, is written in an invalid format, or if any other error occurs.
export fn lookup(name: str) []ip::addr = {
	// XXX: Would be cool if we could do this without allocating anything
	// XXX: Would be cool to have meaningful error handling(?)
	const file = os::open(path)!;
	defer io::close(file);

	let addrs: []ip::addr = [];
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
