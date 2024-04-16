// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use cmd::hare::build;
use fmt;
use fs;
use getopt;
use hare::module;
use hare::parse;
use io;
use os;
use os::exec;
use path;
use strconv;

def VERSION: str = "unknown";
def HAREPATH: str = ".";

const help: []getopt::help = [
	"compile, run, and test Hare programs",
	"<subcommand>",
	"args...",
	("build", [
		"compiles a Hare program or module",
		// XXX: once cross-compiling to different targets (linux,
		// freebsd, etc) is supported, we can probably merge -F with it
		('F', "build for freestanding environment"),
		('q', "build silently"),
		('v', "print executed commands (specify twice to print arguments)"),
		('a', "arch", "set target architecture"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "libname", "link with a system library"),
		('N', "namespace", "override namespace for module"),
		('o', "path", "set output file name"),
		('R', "build in release mode"),
		('T', "tagset", "set/unset build tags"),
		('t', "type", "build type (s/o/bin)"),
		"[path]"
	]: []getopt::help),
	("cache", [
		"manages the build cache",
		('c', "clears the cache"),
	]: []getopt::help),
	("deps", [
		"prints dependency information for a Hare program",
		('d', "print dot syntax for use with graphviz"),
		('T', "tagset", "set/unset build tags"),
		"[path|module]",
	]: []getopt::help),
	("run", [
		"compiles and runs a Hare program or module",
		('q', "build silently"),
		('v', "print executed commands (specify twice to print arguments)"),
		('a', "arch", "set target architecture"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "libname", "link with a system library"),
		('R', "build in release mode"),
		('T', "tagset", "set/unset build tags"),
		"[path [args...]]",
	]: []getopt::help),
	("test", [
		"compiles and runs tests for Hare code",
		('q', "build silently"),
		('v', "print executed commands (specify twice to print arguments)"),
		('a', "arch", "set target architecture"),
		('D', "ident[:type]=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('L', "libdir", "add directory to linker library search path"),
		('l', "libname", "link with a system library"),
		('o', "path", "set output file name"),
		('R', "build in release mode"),
		('T', "tagset", "set/unset build tags"),
		"[path]"
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
		getopt::printusage(os::stderr, os::args[0], help)!;
		os::exit(os::status::FAILURE);
	case let subcmd: (str, *getopt::command) =>
		const task = switch (subcmd.0) {
		case "build", "run", "test" =>
			yield &build;
		case "cache" =>
			yield &cache;
		case "deps" =>
			yield &deps;
		case "version" =>
			yield &version;
		case => abort();
		};
		match (task(subcmd.0, subcmd.1)) {
		case void => void;
		case let e: exec::error =>
			fmt::fatal("Error:", exec::strerror(e));
		case let e: fs::error =>
			fmt::fatal("Error:", fs::strerror(e));
		case let e: io::error =>
			fmt::fatal("Error:", io::strerror(e));
		case let e: module::error =>
			fmt::fatal("Error:", module::strerror(e));
		case let e: path::error =>
			fmt::fatal("Error:", path::strerror(e));
		case let e: parse::error =>
			fmt::fatal("Error:", parse::strerror(e));
		case let e: strconv::error =>
			fmt::fatal("Error:", strconv::strerror(e));
		case let e: unknown_arch =>
			fmt::fatalf("Error: Unknown arch: {}", e);
		case let e: build::unknown_platform =>
			fmt::fatalf("Error: Unknown platform: {}", e);
		case unknown_output =>
			fmt::fatal("Error: Can't guess output in root directory");
		case let e: unknown_type =>
			fmt::fatalf("Error: Unknown build type: {}", e);
		case let e: output_exists =>
			fmt::fatalf("Error: Output path '{}' already exists, but isn't an executable file",
				e);
		case let e: output_failed =>
			fmt::fatalf("Error: Could not open output '{}': {}",
				e.0, fs::strerror(e.1));
		case let e: invalid_namespace =>
			fmt::fatalf("Error: Invalid namespace: {}", e);
		};
	};
};
