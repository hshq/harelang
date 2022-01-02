use errors;
use rt;
use strings;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as an [[stream]] in most situations, but there are some APIs
// which require an [[file]] with some OS-level handle backing it - this type is
// used for such APIs.
//
// On Linux, [[io::file]] is a file descriptor.
export type file = int;

// Opens a Unix file descriptor as a file. This is a low-level interface, to
// open files most programs will use something like [[os::open]]. This function
// is not portable.
export fn fdopen(fd: int) file = fd;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	match (rt::read(fd, buf: *[*]u8, len(buf))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		switch (n) {
		case 0 =>
			return EOF;
		case =>
			return n;
		};
	};
};

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	match (rt::write(fd, buf: *const [*]u8, len(buf))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: size =>
		return n;
	};
};

fn fd_close(fd: file) void = rt::close(fd)!;

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	match (rt::lseek(fd, offs: i64, whence: uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: i64 =>
		return n: off;
	};
};

def SENDFILE_MAX: size = 2147479552z;

fn fd_copy(to: file, from: file) (size | error) = {
	let sum = 0z;
	for (true) {
		let n = match (rt::sendfile(to, from, null, SENDFILE_MAX)) {
		case let err: rt::errno =>
			switch (err) {
			case rt::EINVAL =>
				if (sum == 0) {
					return errors::unsupported;
				};
				return errors::errno(err);
			case =>
				return errors::errno(err);
			};
		case let n: size =>
			yield switch (n) {
			case 0 =>
				break;
			case =>
				yield n;
			};
		};
		sum += n;
	};
	return sum;
};
