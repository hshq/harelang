use errors;
use io;
use linux::io_uring;

// TODO: Better error handling everywhere
def DEFAULT_RING_SIZE: u32 = 512;

// Creates a new io_uring I/O bus.
export fn new() (*bus | errors::error) = {
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

// Destroys an io_uring I/O bus.
export fn destroy(bus: *bus) void = {
	io_uring::finish(&bus.uring);
};

// Submits all pending I/O to the host, without blocking.
export fn submit(bus: *bus) void = {
	io_uring::submit(&bus.uring)!;
};

// Waits until at least one I/O event completes, then returns the result. The
// caller must call [[done]] with the result when done with it.
export fn dispatch(bus: *bus) (result | error) = {
	match (io_uring::peek(&bus.uring)?) {
	case null => void;
	case cqe: *io_uring::cqe =>
		return cqe: result;
	};
	match (io_uring::wait(&bus.uring)) {
	case err: io_uring::error =>
		return err: error;
	case cqe: *io_uring::cqe =>
		return cqe: result;
	};
};

// Returns the [[handle]] which this [[result]] corresponds to.
export fn handleof(res: result) handle = {
	return io_uring::get_user(res): handle;
};

// Discards states associated with an [[result]].
export fn done(bus: *bus, res: result) void = {
	io_uring::cqe_seen(&bus.uring, res);
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
