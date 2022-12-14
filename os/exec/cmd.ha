// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use ascii;
use errors;
use io;
use os;
use strings;

// Prepares a [[command]] based on its name and a list of arguments. The argument
// list should not start with the command name; it will be added for you. The
// argument list is borrowed from the strings you pass into this command.
//
// If 'name' does not contain a '/', the $PATH will be consulted to find the
// correct executable. If path resolution fails, nocmd is returned.
//
//	let cmd = exec::cmd("echo", "hello world");
//	let proc = exec::start(&cmd);
//	let status = exec::wait(&proc);
//	assert(exec::status(status) == 0);
//
// By default, the new command will inherit the current process's environment.
export fn cmd(name: str, args: str...) (command | error) = {
	let env = os::getenvs();
	let cmd = command {
		platform: platform_cmd =
			if (strings::contains(name, '/')) {
				yield match (open(name)) {
				case let p: platform_cmd =>
					yield p;
				case =>
					return nocmd;
				};
			} else {
				yield match (lookup(name)?) {
				case void =>
					return nocmd;
				case let p: platform_cmd =>
					yield p;
				};
			},
		argv = alloc([], len(args) + 1z),
		env = alloc([], len(env)),
		files = [],
		...
	};
	append(cmd.argv, name);
	append(cmd.argv, args...);
	append(cmd.env, env...);
	return cmd;
};

// Sets the 0th value of argv for this command. It is uncommon to need this.
export fn setname(cmd: *command, name: str) void = {
	free(cmd.argv[0]);
	cmd.argv[0] = name;
};

// Frees state associated with a command. You only need to call this if you do
// not execute the command with [[exec]] or [[start]]; in those cases the state is
// cleaned up for you.
export fn finish(cmd: *command) void = {
	platform_finish(cmd);
	free(cmd.argv);
	free(cmd.env);
};

// Executes a prepared command in the current address space, overwriting the
// running process with the new command.
export @noreturn fn exec(cmd: *command) void = {
	defer finish(cmd); // Note: doesn't happen if exec succeeds
	platform_exec(cmd): void;
	abort("os::exec::exec failed");
};

// Starts a prepared command in a new process.
export fn start(cmd: *command) (error | process) = {
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
	free(cmd.env);
	cmd.env = [];
};

// Removes a variable in the command environment. This does not affect the
// current process environment. The 'key' must be a valid environment variable
// name per POSIX definition 3.235. This includes underscores and alphanumeric
// ASCII characters, and cannot begin with a number.
export fn unsetenv(cmd: *command, key: str) (void | errors::invalid) = {
	let iter = strings::iter(key);
	for (let i = 0z; true; i += 1) match (strings::next(&iter)) {
	case void =>
		break;
	case let r: rune =>
		if (i == 0) {
			if(!(r == '_' || ascii::isalpha(r))) {
				return errors::invalid;
			};
		} else {
			if(!(r == '_' || ascii::isalnum(r))) {
				return errors::invalid;
			};
		};
	};

	// XXX: This can be a binary search
	let fullkey = strings::concat(key, "=");
	defer free(fullkey);
	for (let i = 0z; i < len(cmd.env); i += 1) {
		if (strings::hasprefix(cmd.env[i], fullkey)) {
			delete(cmd.env[i]);
			break;
		};
	};
};


// Adds or sets a variable in the command environment. This does not affect the
// current process environment. The 'key' must be a valid environment variable
// name per POSIX definition 3.235. This includes underscores and alphanumeric
// ASCII characters, and cannot begin with a number.
export fn setenv(cmd: *command, key: str, value: str) (void | errors::invalid) = {
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
// 	exec::addfile(&cmd, os::stderr, os::stdout_file);
// 	exec::addfile(&cmd, os::stdout_file, os::stderr);
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
	addfile(cmd, os::stderr, closefd);
};

// Redirects all standard files (stdin, stdout, and stderr) to /dev/null or the
// platform-specific equivalent.
export fn nullstd(cmd: *command) void = {
	addfile(cmd, os::stdin_file, nullfd);
	addfile(cmd, os::stdout_file, nullfd);
	addfile(cmd, os::stderr, nullfd);
};

fn lookup(name: str) (platform_cmd | void | error) = {
	const path = match (os::getenv("PATH")) {
	case void =>
		return;
	case let s: str =>
		yield s;
	};
	let tok = strings::tokenize(path, ":");
	for (true) {
		const item = match (strings::next_token(&tok)) {
		case void =>
			break;
		case let s: str =>
			yield s;
		};
		let path = strings::concat(item, "/", name);
		defer free(path);
		match (open(path)) {
		case (errors::noaccess | errors::noentry) =>
			continue;
		case let err: error =>
			return err;
		case let p: platform_cmd =>
			return p;
		};
	};
};
