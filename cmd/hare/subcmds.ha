use ascii;
use bufio;
use encoding::utf8;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::module;
use os::exec;
use os;
use path;
use strings;

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
		void => return void,
		t: []module::tag => t,
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
		void => return void,
		t: []module::tag => t,
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
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'c' => goal = goal::OBJ,
			'v' => verbose = true,
			'D' => append(defines, opt.1),
			'j' => abort(), // TODO
			'l' => abort(), // TODO
			'o' => output = opt.1,
			't' => abort(), // TODO
			'T' => tags = match (addtags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			'X' => tags = match (deltags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			*   => abort(),
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

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx);
	defer plan_finish(&plan);

	const ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal(
			"Error scanning input module: {}",
			module::strerror(err)),
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
		void => void,
		!exec::exit_status => fmt::fatal("{} {}: build failed",
			os::args[0], os::args[1]),
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
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'v' => verbose = true,
			'D' => append(defines, opt.1),
			'j' => abort(), // TODO
			'l' => abort(), // TODO
			't' => abort(), // TODO
			'T' => tags = match (addtags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			'X' => tags = match (deltags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			*   => abort(),
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

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx);
	defer plan_finish(&plan);

	const ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal(
			"Error scanning input module: {}",
			module::strerror(err)),
	};

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);

	for (let i = 0z; i < len(ver.depends); i += 1z) {
		const dep = ver.depends[i];
		sched_module(&plan, dep, &depends);
	};

	const output = mkfile(&plan, "out");
	sched_hare_exe(&plan, ver, output, depends...);
	match (plan_execute(&plan, verbose)) {
		void => void,
		!exec::exit_status => fmt::fatal("{} {}: build failed",
			os::args[0], os::args[1]),
	};
	const cmd = match (exec::cmd(output, runargs...)) {
		err: exec::error => fmt::fatal("exec: {}", exec::strerror(err)),
		cmd: exec::command => cmd,
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn sched_walk(plan: *plan, ident: ast::ident, link: *[]*task) void = {
	const path = module::identpath(ident);
	const it = os::iter(path)?;
	free(path);
	:loop for (true) match (fs::next(it)) {
		ent: fs::dirent => {
			if (ent.name == "." || ent.name == "..") {
				continue;
			};
			if (ent.ftype & fs::mode::DIR != fs::mode::DIR) {
				continue;
			};
			const d = utf8::decode(ent.name);
			match (utf8::next(&d)) {
				void => break,
				(utf8::more | utf8::invalid) => continue :loop,
				r: rune => if (!ascii::isalpha(r) && r != '_') {
					continue :loop;
				},
			};
			for (true) match (utf8::next(&d)) {
				void => break,
				(utf8::more | utf8::invalid) => continue :loop,
				r: rune => if (!ascii::isalnum(r) && r != '_') {
					continue :loop;
				},
			};
			let new = ast::ident_dup(ident);
			append(new, strings::dup(ent.name));
			sched_walk(plan, new, link);

			match (module::lookup(plan.context, new)) {
				ver: module::version =>
					if (len(ver.inputs) == 0) continue,
				module::error => continue,
			};
			sched_module(plan, new, link);
		},
		void => break,
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
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
			'v' => verbose = true,
			'D' => append(defines, opt.1),
			'j' => abort(), // TODO
			'l' => abort(), // TODO
			't' => abort(), // TODO
			'o' => output = opt.1,
			'T' => tags = match (addtags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			'X' => tags = match (deltags(tags, opt.1)) {
				void => fmt::fatal("Error parsing tags"),
				t: []module::tag => t,
			},
			*   => abort(),
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

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx);
	defer plan_finish(&plan);

	const ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal(
			"Error scanning input module: {}",
			module::strerror(err)),
	};

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);
	sched_walk(&plan, [], &depends);

	const have_output = len(output) != 0;
	if (!have_output) {
		output = mkfile(&plan, "out");
	};
	if (len(ver.inputs) == 0) {
		sched_ld(&plan, strings::dup(output), depends...);
	} else {
		sched_hare_exe(&plan, ver, strings::dup(output), depends...);
	};
	match (plan_execute(&plan, verbose)) {
		void => void,
		!exec::exit_status => fmt::fatal("{} {}: build failed",
			os::args[0], os::args[1]),
	};

	if (have_output) {
		return;
	};

	const cmd = match (exec::cmd(output, runargs...)) {
		err: exec::error => fmt::fatal("exec: {}", exec::strerror(err)),
		cmd: exec::command => cmd,
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

		match (os::getenv("HAREPATH")) {
			void => fmt::printfln("HAREPATH\t{}", HAREPATH)!,
			s: str => {
				fmt::printf("HAREPATH\t{}", s)!;
				bufio::flush(os::stdout)!;
				fmt::errorln("\t(from environment)")!;
			},
		};
	};
};
