use errors;
use io;
use linux::io_uring;

def DEFAULT_RING_SIZE: u32 = 512;

// Creates a new I/O bus.
export fn new() (*bus | error) = {
	let params = io_uring::params { ... };
	match (io_uring::setup(DEFAULT_RING_SIZE, &params)) {
	case err: io_uring::error =>
		return err: error;
	case ring: io_uring::io_uring =>
		return alloc(bus {
			uring = ring,
		});
	};
};

// Destroys an I/O bus.
export fn destroy(bus: *bus) void = {
	io_uring::finish(&bus.uring);
};

// Returns an [[io::file]] for the bus itself.
export fn busfile(bus: *bus) io::file = {
	return bus.uring.fd;
};

// Registers a set of I/O operations with the queue, without submitting them.
// Must call [[submit]] later submit them to the host.
export fn enqueue(bus: *bus, ops: *handle...) void = {
	for (let i = 0z; i < len(ops); i += 1) {
		switch (ops[i].sqe.opcode) {
		case io_uring::op::ACCEPT =>
			ops[i].sqe.addr = &ops[i].accept.sockaddr;
			ops[i].sqe.addr2 = &ops[i].accept.sockaddr_sz;
		case => void;
		};
		io_uring::set_user(ops[i].sqe, ops[i]);
	};
};

// Submits all pending I/O to the host, without blocking, optionally enqueing
// any number of additional operations prior to submission.
export fn submit(bus: *bus, ops: *handle...) (void | error) = {
	enqueue(bus, ops...);
	io_uring::submit(&bus.uring)?;
	return;
};

// Waits until at least one I/O event completes, then returns the result. The
// caller must call [[done]] with the result when done with it.
export fn dispatch(bus: *bus) (result | error) = {
	const res = _dispatch(bus)?;
	const handle = handleof(res);
	for (let i = 0z; i < len(handle.callbacks); i += 1) {
		const cb = handle.callbacks[i];
		cb.0(res, cb.1);
	};
	return res;
};

fn _dispatch(bus: *bus) (result | error) = {
	match (io_uring::peek(&bus.uring)?) {
	case null => void;
	case cqe: *io_uring::cqe =>
		return cqe: result;
	};
	match (io_uring::submit_wait(&bus.uring, 1)) {
	case err: io_uring::error =>
		return err: error;
	case uint => void;
	};
	match (io_uring::peek(&bus.uring)?) {
	case null => abort();
	case cqe: *io_uring::cqe =>
		return cqe: result;
	};
};

// Registers a file with the iobus, returning a [[registered_file]] object to
// use for I/O operations. It is not necessary to register files to use them for
// I/O, but it improves performance if you do.
export fn register_file(bus: *bus, file: io::file) registered_file = {
	let registered: int = -1;
	if (bus.lastfd >= len(bus.fdset)) {
		static const init: [256]int = [-1...];
		append(bus.fdset, init...);
		bus.fdset[bus.lastfd] = file;
		registered = bus.lastfd: int;
		io_uring::register_files(&bus.uring, bus.fdset)!;
	} else {
		let updates = [
			io_uring::files_update {
				offs = bus.lastfd: u32,
				fds = &bus.fdset[bus.lastfd],
			},
		];
		bus.fdset[bus.lastfd] = file;
		registered = bus.lastfd: int;
		io_uring::register_files_update(&bus.uring, updates)!;
	};
	for (bus.fdset[bus.lastfd] != -1; bus.lastfd += 1) void;
	return registered;
};

// Unregisters a file previously registered with [[register_file]].
export fn unregister_file(bus: *bus, file: file) void = {
	const reg = match (file) {
	case reg: registered_file =>
		yield reg;
	case => abort("Cannot unregister non-registered file");
	};
	let updates = [
		io_uring::files_update {
			offs = reg: u32,
			fds = &bus.fdset[reg],
		},
	];
	bus.fdset[reg] = -1;
	bus.lastfd = reg: size;
	io_uring::register_files_update(&bus.uring, updates)!;
};
