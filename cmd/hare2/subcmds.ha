// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use getopt;

fn build(args: []str) void = {
	const help: []getopt::help = [
		"compiles the Hare program at <path>",
		('c', "build object instead of executable"),
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('o', "path", "set output file name"),
		('t', "arch", "set target architecture"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path>"
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn cache(args: []str) void = {
	const help: []getopt::help = [
		"manages the build cache",
		('c', "cleans the specified modules"),
		"modules...",
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn deps(args: []str) void = {
	const help: []getopt::help = [
		"prints dependency information for a Hare program",
		('d', "print dot syntax for use with graphviz"),
		('M', "print rules for POSIX make"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path>",
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn release(args: []str) void = {
	const help: []getopt::help = [
		"prepares a new release for a program or library",
		('d', "enable dry-run mode; do not perform any changes"),
		"<major|minor|patch|x.y.z>",
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn run(args: []str) void = {
	const help: []getopt::help = [
		"compiles and runs the Hare program at <path>",
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path>", "<args...>",
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn test(args: []str) void = {
	const help: []getopt::help = [
		"compiles and runs tests for Hare programs",
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('o', "path", "set output file name"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"[tests...]"
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};

fn version(args: []str) void = {
	const help: []getopt::help = [
		"provides version information for the Hare environment",
		('v', "print more information"),
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);
	abort(); // TODO
};
