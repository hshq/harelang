// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use fmt;
use io;
use iobus;
use os;
use strings;
use unix::poll;

type state = struct {
	mainbus: *iobus::bus,
	userbus: *iobus::bus,
};

export fn main() void = {
	let mainbus = iobus::new()!;
	defer iobus::destroy(mainbus);
	let userbus = iobus::new()!;
	defer iobus::destroy(userbus);

	const userfd = iobus::busfile(userbus);
	defer io::close(userfd);

	const in = iobus::register_file(mainbus, os::stdin_file)!;
	// XXX: io_uring has a somewhat arbitrary limitation on registering
	// another uring as a file, so we can't do this.
	//const userfd = iobus::register_file(mainbus, userfd)!;

	let pollin = iobus::poll(mainbus, in, poll::event::POLLIN)!;
	let polluser = iobus::poll(mainbus, userfd, poll::event::POLLIN)!;

	iobus::enqueue(mainbus, &pollin, &polluser);
	fmt::error("> ")!;

	const write = iobus::write(userbus, os::stdout_file,
		strings::toutf8("hi!\n"), 0)!;
	iobus::submit(userbus, &write)!;

	let state = state {
		mainbus = mainbus,
		userbus = userbus,
	};

	for (true) {
		const res = iobus::dispatch(mainbus)!;
		defer iobus::done(mainbus, res);

		if (iobus::handleof(res) == &pollin) {
			iobus::endpoll(mainbus, res)!;
			if (!readcmd(&state)) {
				fmt::errorln("exit")!;
				break;
			};
			pollin = iobus::poll(mainbus, in, poll::event::POLLIN)!;
			iobus::enqueue(mainbus, &pollin);
		};
		if (iobus::handleof(res) == &polluser) {
			iobus::endpoll(mainbus, res)!;
			polluser = iobus::poll(mainbus, userfd, poll::event::POLLIN)!;
			iobus::enqueue(mainbus, &polluser);

			// TODO: Something more sophisticated than this
			const res = iobus::dispatch(userbus)!;
			iobus::done(userbus, res);
			fmt::errorln("\rcompletion event received")!;
			fmt::error("> ")!;
		};
	};
};

fn readcmd(state: *state) bool = {
	const line = match (bufio::scanline(os::stdin)!) {
	case let line: []u8 =>
		yield strings::fromutf8(line);
	case io::EOF =>
		return false;
	};
	defer free(line);

	fmt::errorfln("{}", line)!;
	fmt::error("> ")!;
	return true;
};
