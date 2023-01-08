// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use getopt;
use os;
use fmt;

def VERSION: str = "unknown";
def PLATFORM: str = "unknown";
def HAREPATH: str = ".";

export fn main() void = {
	const help: []getopt::help = [
		"compile, run, and test Hare programs",
		"<build | cache | deps | release | run | test | version>",
		"args...",
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	if (len(cmd.args) < 1) {
		getopt::printusage(os::stderr, os::args[0], help...);
		os::exit(1);
	};
	const task = switch (cmd.args[0]) {
	case "build" =>
		yield &build;
	case "cache" =>
		yield &cache;
	case "deps" =>
		yield &deps;
	case "release" =>
		yield &release;
	case "run" =>
		yield &run;
	case "test" =>
		yield &test;
	case "version" =>
		yield &version;
	case =>
		getopt::printusage(os::stderr, os::args[0], help...);
		os::exit(1);
	};
	task(cmd.args);
};
