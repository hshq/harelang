use bufio;
use fmt;
use io;
use iobus;
use os;
use strings;
use unix::poll;

export fn main() void = {
	// TODO: It would be nice to have two iobus instances here, one for us
	// (i.e. polling stdin) and one for the user. However, it does not seem
	// to be possible to poll an io_uring fd on Linux 5.10. I have written
	// to the io_uring mailing list for more information.
	let bus = iobus::new()!;
	defer iobus::destroy(bus);

	const in = iobus::register_file(bus, os::stdin_file);
	let poll = iobus::poll(bus, in, poll::event::POLLIN)!;
	iobus::enqueue(bus, &poll);
	fmt::error("> ")!;

	for (true) {
		const res = match (iobus::dispatch(bus)) {
		case err: iobus::error =>
			fmt::fatal("Error dispatching bus: {}",
				iobus::strerror(err));
		case res: iobus::result =>
			yield res;
		};
		defer iobus::done(bus, res);

		if (iobus::handleof(res) == &poll) {
			iobus::endpoll(bus, res)!;
			if (!readcmd(bus)) {
				fmt::errorln("exit")!;
				break;
			};
			poll = iobus::poll(bus, in, poll::event::POLLIN)!;
			iobus::enqueue(bus, &poll);
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
