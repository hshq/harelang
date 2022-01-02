use crypto::random;
use encoding::hex;
use errors;
use fmt;
use fs;
use io;
use os;
use path;
use strio;
use strings;

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
) (io::file | fs::error) = {
	assert(iomode == io::mode::WRITE || iomode == io::mode::RDWR);
	assert(len(mode) == 0 || len(mode) == 1);
	let fmode = if (len(mode) != 0) mode[0] else 0o644: fs::mode;
	let oflags = fs::flags::TMPFILE | fs::flags::EXCL | fs::flags::CLOEXEC;
	if (iomode == io::mode::RDWR) {
		oflags |= fs::flags::RDWR;
	} else {
		oflags |= fs::flags::WRONLY;
	};
	// TODO: Add a custom "close" function which removes the named file
	match (os::create(get_tmpdir(), fmode, oflags)) {
	case let err: fs::error =>
		let file = named(os::cwd, get_tmpdir(), iomode, mode...)?;
		free(file.1);
		return file.0;
	case let f: io::file =>
		return f;
	};
};

// Creates a named temporary file in the given directory of the given
// filesystem. The caller is responsible for removing the file and freeing the
// name when they're done with it.
//
// The I/O mode must be either [[io::mode::WRITE]] or [[io::mode::RDWR]].
//
// Only one variadic argument may be provided, if at all, to specify the mode of
// the new file. The default is 0o644.
export fn named(
	fs: *fs::fs,
	path: str,
	iomode: io::mode,
	mode: fs::mode...
) ((io::file, str) | fs::error) = {
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
		match (fs::create_file(fs, fpath, fmode, oflags)) {
		case errors::exists =>
			continue;
		case let err: fs::error =>
			return err;
		case let f: io::file =>
			return (f, strings::dup(fpath));
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
	hex::encode(&sink, buf) as size;
	let name = strio::string(&sink);

	let path = path::join(get_tmpdir(), name);
	match (os::mkdir(path)) {
	case let err: fs::error => abort("Could not create temp directory");
	case void => void;
	};
	return path;
};
