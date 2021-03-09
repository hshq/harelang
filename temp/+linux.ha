use crypto::random;
use encoding::hex;
use fs;
use io;
use os;
use path;

fn get_tmpdir() path::path = os::tryenv("TMPDIR", "/tmp");

// Creates an unnamed temporary file. The file may or may not have a name; not
// all systems support the creation of temporary inodes which are not linked to
// any directory. If it is necessary to create a real file, it will be removed
// when the stream is closed.
//
// The I/O mode must be either [io::mode::WRITE] or [io::mode::RDWR].
//
// Only one variadic argument may be provided, if at all, to specify the mode of
// the new file. The default is 0o644.
export fn file(
	iomode: io::mode,
	mode: fs::mode...
) (*io::stream | fs::error) = {
	assert(iomode == io::mode::WRITE || iomode == io::mode::RDWR);
	assert(len(mode) == 0 || len(mode) == 1);
	let fmode = if (len(mode) != 0) mode[0] else 0o644: fs::mode;
	let oflags = fs::flags::TMPFILE | fs::flags::EXCL | fs::flags::CLOEXEC;
	if (iomode == io::mode::RDWR) {
		oflags |= fs::flags::RDWR;
	} else {
		oflags |= fs::flags::WRONLY;
	};
	return match (os::create(get_tmpdir(), fmode, oflags)) {
		err: fs::error => abort(), // TODO: Fall back to named file
		s: *io::stream => s,
	};
};

// Creates a named temporary file.
//
// The I/O mode must be either [io::mode::WRITE] or [io::mode::RDWR].
//
// Only one variadic argument may be provided, if at all, to specify the mode of
// the new file. The default is 0o644.
export fn named(
	iomode: io::mode,
	mode: fs::mode...
) (*io::stream | fs::error) = {
	abort(); // TODO
};

// Creates a temporary directory. This function only guarantees that the
// directory will have a unique name and be placed in the system temp directory,
// but not that it will be removed automatically; the caller must remove it when
// they're done using it via [os::rmdir] or [os::rmdirall].
//
// The caller must free the return value with [path::path_free].
export fn dir() path::path = {
	let buf: [16]u8 = [0...];
	random::buffer(buf[..]);
	let name = hex::encode(buf);
	defer free(name);
	let path = path::join(get_tmpdir(), name);
	match (os::mkdir(path)) {
		err: fs::error => abort("Could not create temp directory"),
		void => void,
	};
	return path;
};
