// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use os;
use path;
use unix;

fn lookup(prog: str, var: str, default: str) str = {
	static let buf = path::buffer { ... };
	path::set(&buf)!;
	match (os::getenv(var)) {
	case let s: str =>
		const path = path::push(&buf, s, prog)!;
		if (!path::abs(path)) {
			yield;
		};
		match (os::stat(path)) {
		case let err: fs::error =>
			os::mkdirs(path, 0o755)!;
			return path;
		case let st: fs::filestat =>
			if (fs::isdir(st.mode)) {
				return path;
			};
		};
	case void => void;
	};

	const home = os::getenv("HOME") as str;
	const path = path::set(&buf, home, default, prog)!;
	match (os::mkdirs(path, 0o755)) {
	case let err: fs::error =>
		fmt::fatalf("Error creating {}: {}",
			path, fs::strerror(err));
	case void => void;
	};
	return path;
};

// Returns a directory suitable for storing config files. The "prog" parameter
// should be a descriptive name unique to this program. The return value is
// statically allocated and will be overwritten on subsequent calls to any
// function in the dirs module.
export fn config(prog: str) str = lookup(prog, "XDG_CONFIG_HOME", ".config");

// Returns a directory suitable for cache files. The "prog" parameter should be
// a descriptive name unique to this program. The return value is statically
// allocated and will be overwritten on subsequent calls to any function in the
// dirs module.
export fn cache(prog: str) str = lookup(prog, "XDG_CACHE_HOME", ".cache");

// Returns a directory suitable for persistent data files. The "prog" parameter
// should be a descriptive name unique to this program. The return value is
// statically allocated and will be overwritten on subsequent calls to any
// function in the dirs module.
export fn data(prog: str) str = {
	static let buf = path::buffer { ... };
	const fragment = path::set(&buf, ".local", "share")!;
	return lookup(prog, "XDG_DATA_HOME", fragment);
};

// Returns a directory suitable for storing program state data. The "prog"
// parameter should be a descriptive name unique to this program. The return
// value is statically allocated and will be overwritten on subsequent calls to
// any function in the dirs module.
export fn state(prog: str) str = {
	static let buf = path::buffer { ... };
	const fragment = path::set(&buf, ".local", "state")!;
	return lookup(prog, "XDG_STATE_HOME", fragment);
};

// Returns a directory suitable for storing non-essential runtime files and
// other file objects (such as sockets, named pipes, and so on). Applications
// should use this directory for communication and synchronization purposes and
// should not place larger files in it, since it might reside in runtime memory
// and cannot necessarily be swapped out to disk.
//
// The specification requires the directory to be owned by the current user and
// not be world-readable. No fallback is implemented in case XDG_RUNTIME_DIR is
// unset or incorrectly set up.
export fn runtime() (str | fs::error) = {
	let path = match (os::getenv("XDG_RUNTIME_DIR")) {
	case let path: str =>
		yield path;
	case void =>
		return errors::noentry;
	};

	const st = os::stat(path)?;
	const uid = unix::getuid(): uint;
	if (st.uid != uid || fs::mode_perm(st.mode) != fs::mode::USER_RWX) {
		return errors::noaccess;
	};
	if (!fs::isdir(st.mode)) {
		return fs::wrongtype;
	};

	return path;
};
