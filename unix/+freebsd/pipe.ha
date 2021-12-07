use errors;
use io;
use rt;

// Flags to use for the [[io::file]]s returned by [[pipe]]
// Only CLOEXEC and NONBLOCK are guaranteed to be available.
export type pipe_flag = enum {
	CLOEXEC = rt::O_CLOEXEC,
	DIRECT = rt::O_DIRECT,
	NONBLOCK = rt::O_NONBLOCK,
};

// Create a pair of two linked [[io::file]]s, such that any data written to the
// second [[io::file]] may be read from the first. If no [[pipe_flag]]s are
// provided, [[pipe_flag::CLOEXEC]] is used. If you pass your own flags, it is
// recommended that you add it unless you know that you don't want it.
export fn pipe(flags: pipe_flag...) ((io::file, io::file) | errors::error) = {
	let fds: [2]int = [0...];
	let flag: pipe_flag = if (len(flags) == 0) pipe_flag::CLOEXEC else 0;
	for (let i = 0z; i < len(flags); i += 1) {
		flag |= flags[i];
	};
	match (rt::pipe2(&fds, flag)) {
	case void => void;
	case let e: rt::errno =>
		return errors::errno(e);
	};
	return (fds[0], fds[1]);
};
