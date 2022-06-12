// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Jon Eskin <eskinjp@gmail.com>
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
) (io::file | fs::error) = {
	assert(iomode == io::mode::WRITE || iomode == io::mode::RDWR);
	assert(len(mode) == 0 || len(mode) == 1);
	let fmode = if (len(mode) != 0) mode[0] else 0o644: fs::mode;
	let oflags = fs::flags::TMPFILE | fs::flags::EXCL;
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
// filesystem. The caller is responsible for closing and removing the file when
// they're done with it. The name is statically allocated, and will be
// overwritten on subsequent calls.
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
	let oflags = fs::flags::EXCL;
	if (iomode == io::mode::RDWR) {
		oflags |= fs::flags::RDWR;
	} else {
		oflags |= fs::flags::WRONLY;
	};

	static let pathbuf = path::buffer { ... };
	static let namebuf: [32]u8 = [0...];
	for (true) {
		let rand: [size(u64)]u8 = [0...];
		random::buffer(rand);

		const id = *(&rand[0]: *u64);
		const name = fmt::bsprintf(namebuf, "temp.{}", id);
		const path = path::set(&pathbuf, path, name)!;

		match (fs::create_file(fs, path, fmode, oflags)) {
		case errors::exists =>
			continue;
		case let err: fs::error =>
			return err;
		case let f: io::file =>
			return (f, path);
		};
	};
	abort(); // Unreachable
};

// Creates a temporary directory. This function only guarantees that the
// directory will have a unique name and be placed in the system temp directory,
// but not that it will be removed automatically; the caller must remove it when
// they're done using it via [[os::rmdir]] or [[os::rmdirall]].
//
// The return value is statically allocated and will be overwritten on
// subsequent calls.
export fn dir() str = {
	const buf: [8]u8 = [0...], name: [16]u8 = [0...];
	random::buffer(buf[..]);

	const sink = strio::fixed(name);
	let enc = hex::newencoder(&sink);
	io::write(&enc, buf) as size;
	const name = strio::string(&sink);

	static let buf = path::buffer { ... };
	path::set(&buf, get_tmpdir(), name)!;
	const path = path::string(&buf);
	match (os::mkdir(path, 0o755)) {
	case let err: fs::error => abort("Could not create temp directory");
	case void => void;
	};
	return path;
};
