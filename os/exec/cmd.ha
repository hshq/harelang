use fmt;
use os;
use strings;

// An executable command.
export type command = struct {
	data: platform,
	argv: []str,
	envp: []str,
};

// Returned when path resolution fails to find a command by its name.
export type nocmd = void;

// All errors that can be returned from os::exec.
export type error = (nocmd | os_error);

// Returns a human-readable message for the given error.
export fn errstr(err: error) const str = {
	return match (err) {
		err: os_error => err.string(err.data),
		nocmd         => "Command not found",
	};
};

// Prepares a [command] based on its name and a list of arguments. The argument
// list should not start with the command name; it will be added for you.
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
	let cmd = command {
		data: platform =
			if (strings::contains(name, '/')) match (open(name)) {
				p: platform => p,
				err: os_error => return nocmd,
			} else match (lookup(name)) {
				p: platform => p,
				void => return nocmd,
			},
		argv = alloc([]str, [], len(args) + 1z),
		...
	};
	append(cmd.argv, name);
	for (let i = 0z; i < len(args); i += 1z) {
		append(cmd.argv, args[i]);
	};
	return cmd;
};

// Frees state associated with a command.
export fn finish(cmd: *command) void = {
	platform_finish(cmd);
	free(cmd.argv);
};

// Executes a prepared command in the current address space, overwriting the
// running process with the new command.
export fn exec(cmd: *command) os_error = platform_exec(cmd);

// Starts a prepared command in a new process and calls [finish] on the command.
//
// TODO: Return a handle which gives information about the new process.
export fn start(cmd: *command) (os_error | void) = {
	defer finish(cmd);
	platform_start(cmd);
};

fn lookup(name: str) (platform | void) = {
	const path = match (os::getenv("PATH")) {
		void   => return void,
		s: str => s,
	};
	let tok = strings::tokenize(path, ":");
	for (true) {
		const item = match (strings::next_token(&tok)) {
			void   => break,
			s: str => s,
		};
		let path = strings::concat(item, "/", name);
		defer free(path);
		match (open(path)) {
			err: os_error => continue,
			p: platform => return p,
		};
	};
};
