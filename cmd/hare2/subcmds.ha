// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use fmt;
use fs;
use getopt;
use hare::module2;
use os;
use strings;

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

	const input =
		if (len(cmd.args) == 0) os::getcwd()
		else if (len(cmd.args) == 1) cmd.args[0]
		else {
			getopt::printusage(os::stderr, args[0], help...);
			os::exit(1);
		};

	const conf = module2::config {
		fs = os::cwd,
		tags = default_tags(),
		...
	};
	const ctx = module2::newcontext(&conf);
	defer module2::context_finish(&ctx);

	const root = match (scanroot(&ctx, input)) {
	case let mod: module2::module =>
		yield mod;
	case let err: module2::error =>
		fmt::fatal("Error scanning input module: {}",
			module2::strerror(err));
	};
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

fn default_tags() []module2::tag = {
	return alloc([module2::tag {
		name = strings::dup(os::machine()),
		mode = module2::tag_mode::INCLUSIVE,
	}, module2::tag {
		name = strings::dup(PLATFORM),
		mode = module2::tag_mode::INCLUSIVE,
	}]);
};

// Selects module::scan or module::scanfile as appropriate for a given input.
fn scanroot(
	ctx: *module2::context,
	path: str,
) (module2::module | module2::error) = {
	const st = os::stat(path)?;
	if (fs::isfile(st.mode)) {
		return module2::scanfile(ctx, path);
	} else if (fs::isdir(st.mode)) {
		return module2::scan(ctx, [], path);
	} else if (fs::islink(st.mode)) {
		abort(); // TODO
	} else {
		fmt::fatal("Error: unknown input type");
	};
};
