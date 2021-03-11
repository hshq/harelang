use encoding::hex;
use fmt;
use getopt;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use path;
use strio;
use temp;

export fn main() void = {
	let verbose = false, goal = goal::EXE;
	let output = "";

	let help: []getopt::help = [
		"compile, run, and test Hare programs",
		"<build | run | test | version>", "args...",
	];
	let cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	if (len(cmd.args) < 1) {
		getopt::print_usage(os::stderr, os::args[0], help...);
		os::exit(1);
	};
	if (cmd.args[0] == "build") build(cmd.args)
	else if (cmd.args[0] == "run") run(cmd.args)
	else if (cmd.args[0] == "test") test(cmd.args)
	else if (cmd.args[0] == "version") version(cmd.args)
	else {
		getopt::print_usage(os::stderr, os::args[0], help...);
		os::exit(1);
	};
};
