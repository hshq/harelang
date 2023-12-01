// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use os;
use strings;

export type platform_cmd = io::file;

// Same as [[cmd]] except that executable file is determined by [[io::file]].
// This function is not portable.
export fn cmdfile(file: io::file, name: str, args: str...) command = {
	let cmd = command {
		platform = file,
		argv = alloc([], len(args) + 1),
		env = strings::dupall(os::getenvs()),
		files = [],
		dir = "",
	};
	append(cmd.argv, name);
	append(cmd.argv, args...);
	return cmd;
};
