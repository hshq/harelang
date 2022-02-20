use fs;
use os;
use path;
use io;

fn lookup(prog: str, var: str, default: str) str = {
	static let buf = path::buffer { ... };
	path::reset(&buf);
	match (os::getenv(var)) {
	case let s: str =>
		const path = path::add(&buf, s, prog)!;
		match (os::stat(path)) {
		case let err: fs::error =>
			os::mkdirs(path)!;
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
	os::mkdirs(path)!;
	return path;
};

// Returns a directory suitable for storing config files. The "prog" parameter
// should be a descriptive name unique to this program. The return value is
// statically allocated and will be overwritten on subsequent calls to any
// function in the dirs module.
export fn config(prog: str) str = lookup(prog, "XDG_CONFIG_HOME", ".config");

// Returns an [[fs::fs]] for storing config files. The "prog" parameter
// should be a descriptive name unique to this program.
export fn configfs(prog: str) *fs::fs = os::diropen(config(prog)) as *fs::fs;

// Returns a directory suitable for cache files. The "prog" parameter should be
// a descriptive name unique to this program. The return value is statically
// allocated and will be overwritten on subsequent calls to any function in the
// dirs module.
export fn cache(prog: str) str = lookup(prog, "XDG_CACHE_HOME", ".cache");

// Returns an [[fs::fs]] for cache files.
export fn cachefs(prog: str) *fs::fs = os::diropen(cache(prog)) as *fs::fs;

// Returns a directory suitable for persistent data files. The "prog" parameter
// should be a descriptive name unique to this program. The return value is
// statically allocated and will be overwritten on subsequent calls to any
// function in the dirs module.
export fn data(prog: str) str = {
	static let buf = path::buffer { ... };
	const fragment = path::set(&buf, ".local", "share")!;
	return lookup(prog, "XDG_DATA_HOME", fragment);
};

// Returns an [[fs::fs]] for persistent data files. If "prog" is given, a unique
// path for this program to store data will be returned.
export fn datafs(prog: str) *fs::fs = os::diropen(data(prog)) as *fs::fs;

// Returns a directory suitable for storing program state data. The "prog"
// parameter should be a descriptive name unique to this program. The return
// value is statically allocated and will be overwritten on subsequent calls to
// any function in the dirs module.
export fn state(prog: str) str = {
	static let buf = path::buffer { ... };
	const fragment = path::set(&buf, ".local", "state")!;
	return lookup(prog, "XDG_STATE_HOME", fragment);
};

// Returns an [[fs::fs]] for storing program state data.
export fn statefs(prog: str) *fs::fs = os::diropen(state(prog)) as *fs::fs;
