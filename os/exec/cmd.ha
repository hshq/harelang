use os;
use strings;

// Prepares a [command] based on its name and a list of arguments. The argument
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
	let cmd = command {
		platform: platform_cmd =
			if (strings::contains(name, '/')) match (open(name)) {
				err: os_error => return nocmd,
				p: platform_cmd => p,
			} else match (lookup(name)) {
				void => return nocmd,
				p: platform_cmd => p,
			},
		argv = alloc([], len(args) + 1z),
		...
	};
	append(cmd.argv, name, ...args);
	return cmd;
};

// Frees state associated with a command. You only need to call this if you do
// not execute the command with [exec] or [start]; in those cases the state is
// cleaned up for you.
export fn finish(cmd: *command) void = {
	platform_finish(cmd);
	free(cmd.argv);
};

// Executes a prepared command in the current address space, overwriting the
// running process with the new command.
export fn exec(cmd: *command) error = {
	defer finish(cmd); // Note: doesn't happen if exec succeeds
	return platform_exec(cmd);
};

// Starts a prepared command in a new process.
export fn start(cmd: *command) (error | process) = {
	defer finish(cmd);
	return match (platform_start(cmd)) {
		err: os_error => err,
		proc: process => proc,
	};
};

fn lookup(name: str) (platform_cmd | void) = {
	const path = match (os::getenv("PATH")) {
		void => return,
		s: str => s,
	};
	let tok = strings::tokenize(path, ":");
	for (true) {
		const item = match (strings::next_token(&tok)) {
			void => break,
			s: str => s,
		};
		let path = strings::concat(item, "/", name);
		defer free(path);
		match (open(path)) {
			err: os_error => continue,
			p: platform_cmd => return p,
		};
	};
};
