// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use errors;
use fs;
use io;
use path;
use rt;
use strings;

fn shm_check_fs() bool = {
	match (open(rt::SHMFS_DIR_PATH,
			fs::flag::DIRECTORY | fs::flag::RDONLY)) {
	case fs::error =>
		return false;
	case let fd: io::file =>
		defer io::close(fd)!;

		let sv = rt::statvfs{...};
		let st = rt::st{...};

		if (rt::fstatvfs1(fd, &sv, rt::MNT_NOWAIT) is rt::errno)
			return false;

		if (strings::fromutf8(sv.f_fstypename)! == rt::MOUNT_SHMFS)
			return false;

		if (rt::fstat(fd, &st) is rt::errno)
			return false;

		if ((st.mode & rt::SHMFS_DIR_MODE) != rt::SHMFS_DIR_MODE)
			return false;

		return true;
	};
};

fn shm_get_path(name: const str) (str | fs::error) = {
	if (!shm_check_fs())
		return errors::errno(rt::ENOTSUP): fs::error;

	// The name may start with a slash character.
	if (strings::hasprefix(name, '/')) {
		name = strings::sub(name, 1);
	};

	// We may disallow other slashes (implementation-defined behaviour).
	if (strings::contains(name, '/'))
		return errors::errno(rt::EINVAL): fs::error;

	const _path = strings::concat(
		rt::SHMFS_DIR_PATH, "/", rt::SHMFS_OBJ_PREFIX, name);

	if (len(_path) > path::MAX)
		return errors::errno(rt::ENAMETOOLONG): fs::error;

	return _path;
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
// [[fs::flag::EXCL]], and/or [[fs::flag::TRUNC]], which are supported on all
// POSIX-compatible platforms. Other platforms may support additional
// non-standard flags; consult the shm_open(3) manual for your target system for
// details.
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
	const _path = shm_get_path(name)?;

	const oflag = fsflags_to_bsd(oflag)? | rt::O_CLOEXEC | rt::O_NOFOLLOW;

	match (rt::open(_path, oflag, mode)) {
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
	const _path = shm_get_path(name)?;

	match (rt::unlink(_path)) {
	case void =>
		void;
	case let err: rt::errno =>
		return errors::errno(err): fs::error;
	};
};

@test fn shm_open() void = {
	const name = "/vizzini";
	const value = "inconceivable";
	def length = 13;

	const fd = shm_open(name)!;
	defer shm_unlink(name)!;
	io::trunc(fd, length)!;
	io::write(fd, strings::toutf8(value))!;

	{
		const fd = shm_open(name, fs::flag::RDONLY, 0o600)!;

		let b: [length]u8 = [0...];
		io::read(fd, b)!;
		assert(strings::fromutf8(b)! == value);
	};
};

@test fn shm_get_path() void = {
	assert(shm_get_path("/ab/c") is fs::error);
	assert(shm_get_path("abc"): str == "/var/shm/.shmobj_abc");
	assert(shm_get_path("/abc"): str == "/var/shm/.shmobj_abc");
};
