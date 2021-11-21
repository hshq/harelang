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
	case t: []module::tag =>
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
	case t: []module::tag =>
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
	let libs: []str = [];
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
			abort(); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 'o' =>
			output = opt.1;
		case 't' =>
			abort(); // TODO
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
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
	case ver: module::version =>
		yield ver;
	case err: module::error =>
		fmt::fatal("Error scanning input module: {}",
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
		fmt::fatal("{} {}: build failed", os::args[0], os::args[1]);
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

	const increment = switch (cmd.args[0]) {
	case "major" =>
		yield increment::MAJOR;
	case "minor" =>
		yield increment::MINOR;
	case "patch" =>
		yield increment::PATCH;
	case =>
		// TODO: Manually parse version x.y.z
		getopt::printusage(os::stderr, "release", help);
		os::exit(1);
	};

	match (do_release(increment, dryrun)) {
	case void => void;
	case err: exec::error =>
		fmt::fatal(exec::strerror(err));
	case err: errors::error =>
		fmt::fatal(errors::strerror(err));
	case err: io::error =>
		fmt::fatal(io::strerror(err));
	case err: git_error =>
		fmt::fatal("git: {}", exec::exitstr(err));
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
	let libs: []str = [];
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case 'D' =>
			append(defines, opt.1);
		case 'j' =>
			abort(); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 't' =>
			abort(); // TODO
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
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
	case ver: module::version =>
		yield ver;
	case err: module::error =>
		fmt::fatal("Error scanning input module: {}",
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
		fmt::fatal("{} {}: build failed", os::args[0], os::args[1]);
	};
	const cmd = match (exec::cmd(output, runargs...)) {
	case err: exec::error =>
		fmt::fatal("exec: {}", exec::strerror(err));
	case cmd: exec::command =>
		yield cmd;
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn sched_walk(plan: *plan, ident: ast::ident, link: *[]*task) void = {
	const path = module::identpath(ident);
	const it = os::iter(path)?;
	free(path);
	for (true) :loop {
		match (fs::next(it)) {
		case ent: fs::dirent =>
			if (ent.name == "." || ent.name == "..") {
				continue;
			};
			if (ent.ftype & fs::mode::DIR != fs::mode::DIR) {
				continue;
			};
			const d = utf8::decode(ent.name);
			match (utf8::next(&d)) {
			case void =>
				break;
			case (utf8::more | utf8::invalid) =>
				continue :loop;
			case r: rune =>
				if (!ascii::isalpha(r) && r != '_') {
					continue :loop;
				};
			};
			for (true) match (utf8::next(&d)) {
			case void =>
				break;
			case (utf8::more | utf8::invalid) =>
				continue :loop;
			case r: rune =>
				if (!ascii::isalnum(r) && r != '_') {
					continue :loop;
				};
			};
			let new = ast::ident_dup(ident);
			append(new, strings::dup(ent.name));
			sched_walk(plan, new, link);

			match (module::lookup(plan.context, new)) {
			case ver: module::version =>
				if (len(ver.inputs) == 0) continue;
			case module::error =>
				continue;
			};
			sched_module(plan, new, link);
		case void =>
			break;
		};
	};
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
	let libs: []str = [];
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case 'D' =>
			append(defines, opt.1);
		case 'j' =>
			abort(); // TODO
		case 'l' =>
			append(libs, opt.1);
		case 't' =>
			abort(); // TODO
		case 'o' =>
			output = opt.1;
		case 'T' =>
			tags = match (addtags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
				yield t;
			};
		case 'X' =>
			tags = match (deltags(tags, opt.1)) {
			case void =>
				fmt::fatal("Error parsing tags");
			case t: []module::tag =>
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
	case ver: module::version =>
		yield ver;
	case err: module::error =>
		fmt::fatal("Error scanning input module: {}",
			module::strerror(err));
	};

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);
	sched_walk(&plan, [], &depends);

	const have_output = len(output) != 0;
	if (!have_output) {
		output = mkfile(&plan, "", "out");
	};
	if (len(ver.inputs) == 0) {
		sched_ld(&plan, strings::dup(output), depends...);
	} else {
		sched_hare_exe(&plan, ver, strings::dup(output), depends...);
	};
	match (plan_execute(&plan, verbose)) {
	case void => void;
	case !exec::exit_status =>
		fmt::fatal("{} {}: build failed", os::args[0], os::args[1]);
	};

	if (have_output) {
		return;
	};

	const cmd = match (exec::cmd(output, runargs...)) {
	case err: exec::error =>
		fmt::fatal("exec: {}", exec::strerror(err));
	case cmd: exec::command =>
		yield cmd;
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn version(args: []str) void = {
	const help: []getopt::help = [
		"provides version information for the Hare environment",
		('v', "print more information"),
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
			case env: str =>
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
			case env: str =>
				yield env;
			};
			fmt::printfln("HAREPATH\t{}", val)!;
		};
	};
};
