// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use errors;
use io;
use os;
use path;
use strings;

// Prepares a [[command]] based on its name and a list of arguments. The argument
// list should not start with the command name; it will be added for you. The
// argument list is borrowed from the strings you pass into this command.
//
// If 'name' does not contain a '/', the $PATH will be consulted to find the
// correct executable. If path resolution fails, [[nocmd]] is returned.
//
//	let cmd = exec::cmd("echo", "hello world")!;
//	let proc = exec::start(&cmd)!;
//	let status = exec::wait(&proc)!;
//	assert(exec::check(&status) is void);
//
// By default, the new command will inherit the current process's environment.
export fn cmd(name: str, args: str...) (command | error) = {
	let platcmd = if (strings::contains(name, '/')) {
		yield match (open(name)) {
		case let p: platform_cmd =>
			yield p;
		case =>
			return nocmd;
		};
	} else {
		yield match (lookup_open(name)?) {
		case void =>
			return nocmd;
		case let p: platform_cmd =>
			yield p;
		};
	};
	let cmd = command {
		platform = platcmd,
		argv = alloc([], len(args) + 1),
		env = strings::dupall(os::getenvs()),
		files = [],
		dir = "",
	};
	append(cmd.argv, name);
	append(cmd.argv, args...);
	return cmd;
};

// Sets the 0th value of argv for this command. It is uncommon to need this.
export fn setname(cmd: *command, name: str) void = {
	cmd.argv[0] = name;
};

// Frees state associated with a command. You only need to call this if you do
// not execute the command with [[exec]] or [[start]]; in those cases the state is
// cleaned up for you.
export fn finish(cmd: *command) void = {
	platform_finish(cmd);
	free(cmd.argv);
	free(cmd.files);
	strings::freeall(cmd.env);
};

// Executes a prepared command in the current address space, overwriting the
// running process with the new command.
export fn exec(cmd: *command) never = {
	defer finish(cmd); // Note: doesn't happen if exec succeeds
	platform_exec(cmd): void;
	abort("os::exec::exec failed");
};

// Starts a prepared command in a new process.
export fn start(cmd: *command) (process | error) = {
	defer finish(cmd);
	match (platform_start(cmd)) {
	case let err: errors::error =>
		return err;
	case let proc: process =>
		return proc;
	};
};

// Empties the environment variables for the command. By default, the command
// inherits the environment of the parent process.
export fn clearenv(cmd: *command) void = {
	strings::freeall(cmd.env);
	cmd.env = [];
};

// Removes a variable in the command environment. This does not affect the
// current process environment. The key may not contain '=' or '\0'.
export fn unsetenv(cmd: *command, key: str) (void | errors::invalid) = {
	if (strings::contains(key, '=', '\0')) return errors::invalid;

	// XXX: This can be a binary search
	for (let i = 0z; i < len(cmd.env); i += 1) {
		if (strings::cut(cmd.env[i], "=").0 == key) {
			free(cmd.env[i]);
			delete(cmd.env[i]);
			break;
		};
	};
};

// Adds or sets a variable in the command environment. This does not affect the
// current process environment. The key may not contain '=' or '\0'.
export fn setenv(cmd: *command, key: str, value: str) (void | errors::invalid) = {
	if (strings::contains(value, '\0')) return errors::invalid;
	unsetenv(cmd, key)?;
	append(cmd.env, strings::join("=", key, value));
};

// Configures a file in the child process's file table, such that the file
// described by the 'source' parameter is mapped onto file descriptor slot
// 'child' in the child process via dup(2).
//
// This operation is performed atomically, such that the following code swaps
// stdout and stderr:
//
// 	exec::addfile(&cmd, os::stderr_file, os::stdout_file);
// 	exec::addfile(&cmd, os::stdout_file, os::stderr_file);
//
// Pass [[nullfd]] in the 'source' argument to map the child's file descriptor
// to /dev/null or the appropriate platform-specific equivalent.
//
// Pass [[closefd]] in the 'source' argument to close a file descriptor which
// was not opened with the CLOEXEC flag. Note that Hare opens all files with
// CLOEXEC by default, so this is not usually necessary.
//
// To write to a process's stdin, capture its stdout, or pipe two programs
// together, see the [[pipe]] function.
export fn addfile(
	cmd: *command,
	child: io::file,
	source: (io::file | nullfd | closefd),
) void = {
	append(cmd.files, (source, child));
};

// Closes all standard files (stdin, stdout, and stderr) in the child process.
// Many programs do not work well under these conditions; you may want
// [[nullstd]] instead.
export fn closestd(cmd: *command) void = {
	addfile(cmd, os::stdin_file, closefd);
	addfile(cmd, os::stdout_file, closefd);
	addfile(cmd, os::stderr_file, closefd);
};

// Redirects all standard files (stdin, stdout, and stderr) to /dev/null or the
// platform-specific equivalent.
export fn nullstd(cmd: *command) void = {
	addfile(cmd, os::stdin_file, nullfd);
	addfile(cmd, os::stdout_file, nullfd);
	addfile(cmd, os::stderr_file, nullfd);
};

// Configures the child process's working directory. This does not affect the
// process environment. The path is borrowed from the input, and must outlive
// the command.
export fn chdir(cmd: *command, dir: str) void = {
	cmd.dir = dir;
};

// Similar to [[lookup]] but TOCTOU-proof
fn lookup_open(name: str) (platform_cmd | void | error) = {
	static let buf = path::buffer { ... };
	path::set(&buf)!;

	// Try to open file directly
	if (strings::contains(name, "/")) {
		match (open(name)) {
		case (errors::noaccess | errors::noentry) => void;
		case let err: error =>
			return err;
		case let p: platform_cmd =>
			return p;
		};
	};

	const path = match (os::getenv("PATH")) {
	case void =>
		return;
	case let s: str =>
		yield s;
	};

	let tok = strings::tokenize(path, ":");
	for (let item => strings::next_token(&tok)) {
		path::set(&buf, item, name)!;

		match (open(path::string(&buf))) {
		case (errors::noaccess | errors::noentry) =>
			continue;
		case let err: error =>
			return err;
		case let p: platform_cmd =>
			return p;
		};
	};
};

// Looks up an executable by name in the system PATH. The return value is
// statically allocated.
//
// The use of this function is lightly discouraged if [[cmd]] is suitable;
// otherwise you may have a TOCTOU issue.
export fn lookup(name: str) (str | void) = {
	static let buf = path::buffer { ... };
	path::set(&buf)!;

	// Try to open file directly
	if (strings::contains(name, "/")) {
		match (os::access(name, os::amode::X_OK)) {
		case let exec: bool =>
			if (exec) {
				return name;
			};
		case => void; // Keep looking
		};
	};

	const path = match (os::getenv("PATH")) {
	case void =>
		return;
	case let s: str =>
		yield s;
	};

	let tok = strings::tokenize(path, ":");
	for (let item => strings::next_token(&tok)) {
		path::set(&buf, item, name)!;

		match (os::access(path::string(&buf), os::amode::X_OK)) {
		case let exec: bool =>
			if (exec) {
				return path::string(&buf);
			};
		case => void; // Keep looking
		};
	};
};
