use crypto::random;
use encoding::hex;
use errors;
use fmt;
use fs;
use io;
use os;
use path;
use strio;

fn get_tmpdir() str = os::tryenv("TMPDIR", "/tmp");

// Creates an unnamed temporary file. The file may or may not have a name; not
// all systems support the creation of temporary inodes which are not linked to
// any directory. If it is necessary to create a real file, it will be removed
// when the stream is closed.
//
// The I/O mode must be either [[io::mode::WRITE]] or [[io::mode::RDWR]].
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
		// TODO: Add a custom "close" function which removes the named
		// file
		err: fs::error => named(get_tmpdir(), iomode, mode...),
		s: *io::stream => s,
	};
};

// Creates a named temporary file in the given directory. The path to the
// temporary file may be found via the name field of [[io::stream]]. The caller
// is responsible for removing the file when they're done with it.
//
// The I/O mode must be either [[io::mode::WRITE]] or [[io::mode::RDWR]].
//
// Only one variadic argument may be provided, if at all, to specify the mode of
// the new file. The default is 0o644.
export fn named(
	path: str,
	iomode: io::mode,
	mode: fs::mode...
) (*io::stream | fs::error) = {
	assert(iomode == io::mode::WRITE || iomode == io::mode::RDWR);
	assert(len(mode) == 0 || len(mode) == 1);

	let fmode = if (len(mode) != 0) mode[0] else 0o644: fs::mode;
	let oflags = fs::flags::EXCL | fs::flags::CLOEXEC;
	if (iomode == io::mode::RDWR) {
		oflags |= fs::flags::RDWR;
	} else {
		oflags |= fs::flags::WRONLY;
	};

	// TODO: Use path::pathbuf
	static let pathbuf: [4096]u8 = [0...];
	for (true) {
		let rand: [size(u64)]u8 = [0...];
		random::buffer(rand);
		const id = *(&rand[0]: *u64);
		const fpath = fmt::bsprintf(pathbuf, "{}/temp.{}", path, id);
		match (os::create(fpath, fmode, oflags)) {
			errors::exists => continue,
			err: fs::error => return err,
			s: *io::stream => return s,
		};
	};
	abort(); // Unreachable
};

// Creates a temporary directory. This function only guarantees that the
// directory will have a unique name and be placed in the system temp directory,
// but not that it will be removed automatically; the caller must remove it when
// they're done using it via [[os::rmdir]] or [[os::rmdirall]].
//
// The caller must free the return value.
export fn dir() str = {
	let buf: [8]u8 = [0...], name: [16]u8 = [0...];
	random::buffer(buf[..]);

	let sink = strio::fixed(name);
	defer io::close(sink);
	hex::encode(sink, buf) as size;
	let name = strio::string(sink);

	let path = path::join(get_tmpdir(), name);
	match (os::mkdir(path)) {
		err: fs::error => abort("Could not create temp directory"),
		void => void,
	};
	return path;
};
