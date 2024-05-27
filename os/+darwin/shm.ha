// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use path;
use rt;
use strings;

fn shm_path(name: str) (str | fs::error) = {
	const name = strings::ltrim(name, '/');
	if (len(name) > rt::NAME_MAX) {
		return errors::invalid;
	};
	if (name == "." || name == "..") {
		return errors::invalid;
	};
	static let buf = path::buffer { ... };
	path::set(&buf, "/", name)!;
	return path::string(&buf);
};

// Opens (or creates, given [[fs::flag::CREATE]]) a global shared memory file
// with the given name, suitable for use with [[io::mmap]] to establish shared
// memory areas with other processes using the same name.
//
// The name must not contain any forward slashes (one is permissible at the
// start, e.g. "/example") and cannot be "." or "..".
//
// The "oflag" parameter, if provided, must include either [[fs::flag::RDONLY]]
// or [[fs::flag::RDWR]], and may optionally add [[fs::flag::CREATE]],
// [[fs::flag::EXCL]], and/or [[fs::flag::TRUNC]], other flags are silently
// ignored if set.
//
// The new file descriptor always has CLOEXEC set regardless of the provided
// flags. If creating a new shared memory object, set its initial size with
// [[io::trunc]] before mapping it with [[io::mmap]].
//
// Call [[shm_unlink]] to remove the global shared memory object.
export fn shm_open(
	name: str,
	oflag: fs::flag = fs::flag::CREATE | fs::flag::RDWR,
	mode: fs::mode = 0o600,
) (io::file | fs::error) = {
	const path = shm_path(name)?;
	def VALID_FLAGS: int = rt::O_RDONLY | rt::O_RDWR | rt::O_CREAT | rt::O_EXCL | rt::O_TRUNC;
	const oflag = (fsflags_to_bsd(oflag)? & VALID_FLAGS) | rt::O_CLOEXEC;

	match (rt::shm_open(path, oflag, mode: rt::mode_t)) {
	case let fd: int =>
		return fd: io::file;
	case let err: rt::errno =>
		return errors::errno(err): fs::error;
	};
};

// Removes the shared memory object with the given name. Processes which already
// hold a reference to the file may continue to use the memory associated with
// it. Once all processes have unmapped the associated shared memory object, or
// exited, the memory is released.
export fn shm_unlink(name: str) (void | fs::error) = {
	const path = shm_path(name)?;
	match (rt::shm_unlink(path)) {
	case let err: rt::errno =>
		return errors::errno(err): fs::error;
	case void =>
		return;
	};
};
