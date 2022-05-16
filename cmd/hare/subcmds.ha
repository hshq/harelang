// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use ascii;
use bufio;
use encoding::utf8;
use errors;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use path;
use strings;
use unix::tty;

fn default_tags() []module::tag = {
	return alloc([module::tag {
		name = strings::dup(os::machine()),
		mode = module::tag_mode::INCLUSIVE,
	}, module::tag {
		name = strings::dup(PLATFORM),
		mode = module::tag_mode::INCLUSIVE,
	}]);
};

fn addtags(tags: []module::tag, in: str) ([]module::tag | void) = {
	let in = match (module::parsetags(in)) {
	case void =>
		return void;
	case let t: []module::tag =>
		yield t;
	};
	defer free(in);
	append(tags, in...);
	return tags;
};

fn deltags(tags: []module::tag, in: str) ([]module::tag | void) = {
	if (in == "^") {
		module::tags_free(tags);
		return [];
	};
	let in = match (module::parsetags(in)) {
	case void =>
		return void;
	case let t: []module::tag =>
		yield t;
	};
	defer free(in);
	for (let i = 0z; i < len(tags); i += 1) {
		for (let j = 0z; j < len(in); j += 1) {
			if (tags[i].name == in[j].name
					&& tags[i].mode == in[j].mode) {
				delete(tags[i]);
				i -= 1;
			};
		};
	};
	return tags;
};

type goal = enum {
	OBJ,
	EXE,
};

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

	let tags = default_tags();
	defer module::tags_free(tags);

	let verbose = false;
	let output = "";
	let goal = goal::EXE;
	let defines: []str = [];
	defer free(defines);
	let libs: []str = [];
	defer free(libs);
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'c' =>
			goal = goal::OBJ;
		case 'v' =>
			verbose = true;
		case 'D' =>
			append(defines, opt.1);
		case 'j' =>
			abort("-j option not implemented yet."); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 'o' =>
			output = opt.1;
		case 't' =>
			abort("-t option not implemented yet."); // TODO
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case =>
			abort();
		};
	};

	assert(goal == goal::EXE); // TODO

	const input =
		if (len(cmd.args) == 0) os::getcwd()
		else if (len(cmd.args) == 1) cmd.args[0]
		else {
			getopt::printusage(os::stderr, args[0], help...);
			os::exit(1);
		};

	if (len(libs) > 0) {
		append(tags, module::tag {
			mode = module::tag_mode::INCLUSIVE,
			name = strings::dup("libc"),
		});
	};

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx, libs);
	defer plan_finish(&plan);

	const ver = match (module::scan(&ctx, input)) {
	case let ver: module::version =>
		yield ver;
	case let err: module::error =>
		fmt::fatal("Error scanning input module:",
			module::strerror(err));
	};

	const depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);

	for (let i = 0z; i < len(ver.depends); i += 1z) {
		const dep = ver.depends[i];
		sched_module(&plan, dep, &depends);
	};

	// TODO: Choose this more intelligently
	if (output == "") {
		output = path::basename(ver.basedir);
	};
	sched_hare_exe(&plan, ver, output, depends...);
	match (plan_execute(&plan, verbose)) {
	case void => void;
	case !exec::exit_status =>
		fmt::fatalf("{} {}: build failed", os::args[0], os::args[1]);
	};
	if (tty::isatty(os::stdout_file)) {
		fmt::print("\a")!;
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

	abort("cache subcommand not implemented yet."); // TODO
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

	abort("deps subcommand not implemented yet."); // TODO
};

fn release(args: []str) void = {
	const help: []getopt::help = [
		"prepares a new release for a program or library",
		('d', "enable dry-run mode; do not perform any changes"),
		"<major|minor|patch|x.y.z>",
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	let dryrun = false;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'd' =>
			dryrun = true;
		case => abort();
		};
	};

	if (len(cmd.args) == 0) {
		getopt::printusage(os::stderr, "release", help);
		os::exit(1);
	};

	const next = switch (cmd.args[0]) {
	case "major" =>
		yield increment::MAJOR;
	case "minor" =>
		yield increment::MINOR;
	case "patch" =>
		yield increment::PATCH;
	case =>
		yield match (parseversion(cmd.args[0])) {
		case badversion =>
			getopt::printusage(os::stderr, "release", help);
			os::exit(1);
		case let ver: modversion =>
			yield ver;
		};
	};

	match (do_release(next, dryrun)) {
	case void => void;
	case let err: exec::error =>
		fmt::fatal(exec::strerror(err));
	case let err: errors::error =>
		fmt::fatal(errors::strerror(err));
	case let err: io::error =>
		fmt::fatal(io::strerror(err));
	case let err: fs::error =>
		fmt::fatal(fs::strerror(err));
	case let err: git_error =>
		fmt::fatal("git:", exec::exitstr(err));
	case badversion =>
		fmt::fatal("Error: invalid format string. Hare uses semantic versioning, in the form major.minor.patch.");
	};
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

	let tags = default_tags();
	defer module::tags_free(tags);

	let verbose = false;
	let defines: []str = [];
	defer free(defines);
	let libs: []str = [];
	defer free(libs);
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case 'D' =>
			append(defines, opt.1);
		case 'j' =>
			abort("-j option not implemented yet."); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 't' =>
			abort("-t option not implemented yet."); // TODO
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case =>
			abort();
		};
	};

	let input = "";
	let runargs: []str = [];
	if (len(cmd.args) == 0) {
		input = os::getcwd();
	} else {
		input = cmd.args[0];
		runargs = cmd.args[1..];
	};

	if (len(libs) > 0) {
		append(tags, module::tag {
			mode = module::tag_mode::INCLUSIVE,
			name = strings::dup("libc"),
		});
	};

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx, libs);
	defer plan_finish(&plan);

	const ver = match (module::scan(&ctx, input)) {
	case let ver: module::version =>
		yield ver;
	case let err: module::error =>
		fmt::fatal("Error scanning input module:",
			module::strerror(err));
	};

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);

	for (let i = 0z; i < len(ver.depends); i += 1z) {
		const dep = ver.depends[i];
		sched_module(&plan, dep, &depends);
	};

	const output = mkfile(&plan, "", "out");
	sched_hare_exe(&plan, ver, output, depends...);
	match (plan_execute(&plan, verbose)) {
	case void => void;
	case !exec::exit_status =>
		fmt::fatalf("{} {}: build failed", os::args[0], os::args[1]);
	};
	const cmd = match (exec::cmd(output, runargs...)) {
	case let err: exec::error =>
		fmt::fatal("exec:", exec::strerror(err));
	case let cmd: exec::command =>
		yield cmd;
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
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

	let tags = default_tags();
	defer module::tags_free(tags);
	append(tags, module::tag {
		name = strings::dup("test"),
		mode = module::tag_mode::INCLUSIVE,
	});

	let output = "";
	let verbose = false;
	let defines: []str = [];
	defer free(defines);
	let libs: []str = [];
	defer free(libs);
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case 'D' =>
			append(defines, opt.1);
		case 'j' =>
			abort("-j option not implemented yet."); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 't' =>
			abort("-t option not implemented yet."); // TODO
		case 'o' =>
			output = opt.1;
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case let t: []module::tag =>
				yield t;
			};
		case =>
			abort();
		};
	};

	let input = "";
	let runargs: []str = [];
	if (len(cmd.args) == 0) {
		input = os::getcwd();
	} else {
		input = cmd.args[0];
		runargs = cmd.args[1..];
	};

	if (len(libs) > 0) {
		append(tags, module::tag {
			mode = module::tag_mode::INCLUSIVE,
			name = strings::dup("libc"),
		});
	};

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx, libs);
	defer plan_finish(&plan);

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);

	let items = match (module::walk(&ctx, input)) {
	case let items: []ast::ident =>
		yield items;
	case let err: module::error =>
		fmt::fatal("Error scanning source root:",
			module::strerror(err));
	};

	defer module::walk_free(items);
	for (let i = 0z; i < len(items); i += 1) {
		if (len(items[i]) > 0 && items[i][0] == "cmd") {
			continue;
		};
		match (module::lookup(plan.context, items[i])) {
		case let ver: module::version =>
			if (len(ver.inputs) == 0) continue;
		case module::error =>
			continue;
		};
		sched_module(&plan, items[i], &depends);
	};

	const have_output = len(output) != 0;
	if (!have_output) {
		output = mkfile(&plan, "", "out");
	};
	sched_ld(&plan, strings::dup(output), depends...);
	match (plan_execute(&plan, verbose)) {
	case void => void;
	case !exec::exit_status =>
		fmt::fatalf("{} {}: build failed", os::args[0], os::args[1]);
	};

	if (have_output) {
		return;
	};

	const cmd = match (exec::cmd(output, runargs...)) {
	case let err: exec::error =>
		fmt::fatal("exec:", exec::strerror(err));
	case let cmd: exec::command =>
		yield cmd;
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn version(args: []str) void = {
	const help: []getopt::help = [
		"provides version information for the Hare environment",
		('v', "print build parameters"),
	];
	const cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	let verbose = false;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		// The only option is verbose
		verbose = true;
	};

	fmt::printfln("Hare {}", VERSION)!;

	if (verbose) {
		fmt::errorln()!;
		fmt::printf("Build tags\t")!;
		const tags = default_tags();
		for (let i = 0z; i < len(tags); i += 1) {
			const tag = tags[i];
			const inclusive = (tag.mode & module::tag_mode::INCLUSIVE) == 0;
			fmt::printf("{}{}", if (inclusive) '+' else '-', tag.name)!;
		};
		fmt::println()!;

		if (tty::isatty(os::stdout_file)) {
			// Pretty print
			match (os::getenv("HAREPATH")) {
			case void =>
				const items = strings::split(HAREPATH, ":");
				defer free(items);
				const items = strings::join("\n\t\t", items...);
				defer free(items);
				fmt::printfln("HAREPATH\t{}", items)!;
			case let env: str =>
				fmt::printf("HAREPATH\t")!;
				bufio::flush(os::stdout)!;
				fmt::errorf("(from environment)")!;
				const items = strings::split(env, ":");
				defer free(items);
				const items = strings::join("\n\t\t", items...);
				defer free(items);
				fmt::printfln("\n\t\t{}", items)!;
			};
		} else {
			// Print for ease of machine parsing
			const val = match (os::getenv("HAREPATH")) {
			case void =>
				yield HAREPATH;
			case let env: str =>
				yield env;
			};
			fmt::printfln("HAREPATH\t{}", val)!;
		};
	};
};
