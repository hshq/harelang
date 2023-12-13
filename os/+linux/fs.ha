// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use path;
use rt;
use types::c;

@init fn init_cwd() void = {
	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(rt::AT_FDCWD, &cwd_fs);
};

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = c::tostr(rt::getcwd() as *const u8: *const c::char)!;

// Change the current working directory.
export fn chdir(target: (*fs::fs | str)) (void | fs::error) = {
	const path: str = match (target) {
	case let fs: *fs::fs =>
		assert(fs.open == &fs_open);
		let fs = fs: *os_filesystem;
		match (rt::fchdir(fs.dirfd)) {
		case let err: rt::errno =>
			return errno_to_fs(err);
		case void =>
			return;
		};
	case let s: str =>
		yield s;
	};
	match (rt::chdir(path)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: str) (void | fs::error) = {
	match (rt::chroot(target)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a FIFO node. This function is only available on Unix systems.
export fn mkfifo(path: str, mode: fs::mode) (void | fs::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFIFO, 0)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a block device node. This function is only available on Unix-like
// systems.
export fn mkblk(
	path: str,
	mode: fs::mode,
	major: uint,
	minor: uint,
) (void | fs::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFBLK,
			rt::mkdev(major: u32, minor: u32))) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a character device node. This function is only available on Unix-like
// systems.
export fn mkchr(
	path: str,
	mode: fs::mode,
	major: uint,
	minor: uint,
) (void | fs::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path, mode: rt::mode_t | rt::S_IFCHR,
			rt::mkdev(major: u32, minor: u32))) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a regular file. This function is only available on Unix-like systems.
// This function should only be used if you have a special reason; most of the
// time you should use [[create]] instead.
export fn mkfile(path: str, mode: fs::mode) (void | fs::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFREG, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Access modes for [[access]].
export type amode = enum int {
	F_OK = rt::F_OK,
	R_OK = rt::R_OK,
	W_OK = rt::W_OK,
	X_OK = rt::X_OK,
};

// Returns true if the given mode of access is permissible. The use of this
// function is discouraged as it can allow for a race condition to occur betwen
// testing for the desired access mode and actually using the file should the
// permissions of the file change between these operations. It is recommended
// instead to attempt to use the file directly and to handle any errors that
// should occur at that time.
export fn access(path: str, mode: amode) (bool | fs::error) = {
	match (rt::access(path, mode)) {
	case let b: bool =>
		return b;
	case let err: rt::errno =>
		return errno_to_fs(err);
	};
};
