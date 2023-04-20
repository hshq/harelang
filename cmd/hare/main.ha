// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use getopt;
use os;
use fmt;

def VERSION: str = "unknown";
def PLATFORM: str = "unknown";
def HAREPATH: str = ".";

const help: []getopt::help = [
	"compile, run, and test Hare programs",
	"<subcommand>",
	"args...",
	("build", [
		"compiles the Hare program at <path>",
		('c', "build object instead of executable"),
		('v', "print executed commands"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "name", "link with a system library"),
		('N', "namespace", "override namespace for module"),
		('o', "path", "set output file name"),
		('t', "arch", "set target architecture"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path>"
	]: []getopt::help),
	("cache", [
		"manages the build cache",
		('c', "cleans the specified modules"),
		"modules...",
	]: []getopt::help),
	("deps", [
		"prints dependency information for a Hare program",
		('d', "print dot syntax for use with graphviz"),
		('M', "build-dir", "print rules for POSIX make"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path|module>",
	]: []getopt::help),
	("release", [
		"prepares a new release for a program or library",
		('d', "enable dry-run mode; do not perform any changes"),
		"<major|minor|patch|x.y.z>",
	]: []getopt::help),
	("run", [
		"compiles and runs the Hare program at <path>",
		('v', "print executed commands"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "name", "link with a system library"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path>", "<args...>",
	]: []getopt::help),
	("test", [
		"compiles and runs tests for Hare programs",
		('v', "print executed commands"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "name", "link with a system library"),
		('o', "path", "set output file name"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"[tests...]"
	]: []getopt::help),
	("version", [
		"provides version information for the Hare environment",
		('v', "print build parameters"),
	]: []getopt::help),
];

export fn main() void = {
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	match (cmd.subcmd) {
	case void =>
		getopt::printusage(os::stderr, os::args[0], help...)!;
		os::exit(1);
	case let subcmd: (str, *getopt::command) =>
		const task = switch (subcmd.0) {
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
		};
		task(subcmd.1);
	};
};
