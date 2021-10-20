use bufio;
use fmt;
use io;
use iobus;
use os;
use strings;
use unix::poll;
use unix::poll::{event};

export fn main() void = {
	let bus = iobus::new()!;
	defer iobus::destroy(bus);

	const pollfd = [
		poll::pollfd {
			fd = os::stdin_file,
			events = event::POLLIN,
			...
		},
		poll::pollfd {
			fd = iobus::busfile(bus),
			events = event::POLLIN,
			...
		},
	];
	fmt::error("> ")!;

	for (true) {
		let events = poll::poll(pollfd, poll::INDEF)!;
		if (pollfd[0].revents & event::POLLIN > 0) {
			if (!readcmd(bus)) {
				fmt::errorln("exit")!;
				break;
			};
		};
		if (pollfd[1].revents & event::POLLIN > 0) {
			void; // TODO
		};
	};
};

fn readcmd(bus: *iobus::bus) bool = {
	const line = match (bufio::scanline(os::stdin)!) {
	case line: []u8 =>
		yield strings::fromutf8(line);
	case io::EOF =>
		return false;
	};
	defer free(line);

	fmt::errorfln("{}", line)!;
	fmt::error("> ")!;
	return true;
};
