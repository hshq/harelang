// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::random;
use encoding::hex;
use errors;
use fmt;
use fs;
use io;
use memio;
use os;
use path;

fn get_tmpdir() str = os::tryenv("TMPDIR", "/tmp");

// Creates an unnamed temporary file. The file may or may not have a name; not
// all systems support the creation of temporary inodes which are not linked to
// any directory. If it is necessary to create a real file, it will be removed
// when the stream is closed.
//
// The I/O mode must be either [[io::mode::WRITE]] or [[io::mode::RDWR]].
export fn file(iomode: io::mode, mode: fs::mode) (io::file | fs::error) = {
	// TODO: Add a custom "close" function which removes the named file
	let file = named(os::cwd, get_tmpdir(), iomode, mode)?;
	free(file.1);
	return file.0;
};

// Creates a named temporary file in the given directory of the given
// filesystem. The caller is responsible for closing and removing the file when
// they're done with it. The name is statically allocated, and will be
// overwritten on subsequent calls.
//
// The I/O mode must be either [[io::mode::WRITE]] or [[io::mode::RDWR]].
export fn named(
	fs: *fs::fs,
	path: str,
	iomode: io::mode,
	mode: fs::mode,
) ((io::file, str) | fs::error) = {
	assert(iomode == io::mode::WRITE || iomode == io::mode::RDWR);

	let oflags = fs::flag::EXCL;
	if (iomode == io::mode::RDWR) {
		oflags |= fs::flag::RDWR;
	} else {
		oflags |= fs::flag::WRONLY;
	};

	static let pathbuf = path::buffer { ... };
	static let namebuf: [32]u8 = [0...];
	for (true) {
		let rand: [size(u64)]u8 = [0...];
		random::buffer(rand);

		const id = *(&rand[0]: *u64);
		const name = fmt::bsprintf(namebuf, "temp.{}", id);
		const path = path::set(&pathbuf, path, name)!;

		match (fs::create_file(fs, path, mode, oflags)) {
		case errors::exists =>
			continue;
		case let err: fs::error =>
			return err;
		case let f: io::file =>
			return (f, path);
		};
	};
};

// Creates a temporary directory. This function only guarantees that the
// directory will have a unique name and be placed in the system temp directory,
// but not that it will be removed automatically; the caller must remove it when
// they're done using it via [[os::rmdir]] or [[os::rmdirall]].
//
// The return value is statically allocated and will be overwritten on
// subsequent calls.
export fn dir() str = {
	let buf: [8]u8 = [0...], name: [16]u8 = [0...];
	random::buffer(buf[..]);

	let sink = memio::fixed(name);
	const enc = hex::newencoder(&sink);
	io::write(&enc, buf)!;
	let name = memio::string(&sink)!;

	static let buf = path::buffer { ... };
	path::set(&buf, get_tmpdir(), name)!;
	const path = path::string(&buf);
	match (os::mkdir(path,0o755)) {
	case let err: fs::error => abort("Could not create temp directory");
	case void => void;
	};
	return path;
};
