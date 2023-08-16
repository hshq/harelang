// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use ascii;
use bufio;
use encoding::utf8;
use errors;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::module;
use hare::parse;
use io;
use os::exec;
use os;
use path;
use sort;
use strings;
use unix::tty;

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
				free(tags[i].name);
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

fn build(cmd: *getopt::command) void = {
	let build_target = default_target();
	let tags = module::tags_dup(build_target.tags);
	defer module::tags_free(tags);

	let verbose = false;
	let output = "";
	let goal = goal::EXE;
	let defines: []str = [];
	defer free(defines);
	let libdir: []str = [];
	defer free(libdir);
	let libs: []str = [];
	defer free(libs);
	let namespace: ast::ident = [];
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
		case 'L' =>
			append(libdir, opt.1);
		case 'l' =>
			append(libs, opt.1);
		case 'N' =>
			namespace = match (parse::identstr(opt.1)) {
			case let id: ast::ident =>
				yield id;
			case let err: parse::error =>
				fmt::fatalf("Error parsing namespace {}: {}",
					opt.1, parse::strerror(err));
			};
		case 'o' =>
			output = opt.1;
		case 't' =>
			match (get_target(opt.1)) {
			case void =>
				fmt::fatalf("Unsupported target '{}'", opt.1);
			case let t: *target =>
				build_target = t;
				module::tags_free(tags);
				tags = module::tags_dup(t.tags);
			};
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

	const input =
		if (len(cmd.args) == 0) os::getcwd()
		else if (len(cmd.args) == 1) cmd.args[0]
		else {
			getopt::printusage(os::stderr, "build", cmd.help...)!;
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

	const plan = mkplan(&ctx, libdir, libs, build_target);
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
	switch (goal) {
	case goal::EXE =>
		sched_hare_exe(&plan, ver, output, depends...);
	case goal::OBJ =>
		let task = sched_hare_object(&plan, ver,
			namespace, output, depends...);
		append(plan.scheduled, task);
	};
	match (plan_execute(&plan, verbose)) {
	case void => void;
	case !exec::exit_status =>
		fmt::fatalf("{} build: build failed", os::args[0]);
	};
};

fn cache(cmd: *getopt::command) void = {
	abort("cache subcommand not implemented yet."); // TODO
};

type deps_goal = enum {
	DOT,
	MAKE,
	TERM,
};

fn deps(cmd: *getopt::command) void = {
	let build_target = default_target();
	let tags = module::tags_dup(build_target.tags);
	defer module::tags_free(tags);

	let build_dir: str = "";
	let goal = deps_goal::TERM;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
		case 'd' =>
			goal = deps_goal::DOT;
		case 'M' =>
			goal = deps_goal::MAKE;
			build_dir = opt.1;
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

	const input =
		if (len(cmd.args) == 0) os::getcwd()
		else if (len(cmd.args) == 1) cmd.args[0]
		else {
			getopt::printusage(os::stderr, "deps", cmd.help...)!;
			os::exit(1);
		};

	const ctx = module::context_init(tags, [], HAREPATH);
	defer module::context_finish(&ctx);

	const ver = match (parse::identstr(input)) {
	case let ident: ast::ident =>
		yield match (module::lookup(&ctx, ident)) {
		case let ver: module::version =>
			yield ver;
		case let err: module::error =>
			fmt::fatal("Error scanning input module:",
				module::strerror(err));
		};
	case parse::error =>
		yield match (module::scan(&ctx, input)) {
		case let ver: module::version =>
			yield ver;
		case let err: module::error =>
			fmt::fatal("Error scanning input path:",
				module::strerror(err));
		};
	};

	let visited: []depnode = [];
	let stack: []str = [];
	defer free(stack);
	const ctx = module::context_init([], [], HAREPATH);

	let toplevel = depnode{ident = strings::dup(path::basename(input)), depends = [], depth = 0};

	for (let i = 0z; i < len(ver.depends); i += 1) {
		const name = strings::join("::", ver.depends[i]...);
		defer free(name);
		const child = match (explore_deps(&ctx, &stack, &visited, name)) {
		case let index: size => yield index;
		case let start: dep_cycle =>
			const chain = strings::join(" -> ", stack[start..]...);
			defer free(chain);
			fmt::errorln("Dependency cycle detected:", chain)!;
			os::exit(1);
		};
		append(toplevel.depends, child);
	};

	sort::sort(toplevel.depends, size(size), &cmpsz);
	append(visited, toplevel);
	defer for (let i = 0z; i < len(visited); i += 1) {
		free(visited[i].ident);
		free(visited[i].depends);
	};

	switch (goal) {
	case deps_goal::TERM =>
		show_deps(&visited);
	case deps_goal::DOT =>
		fmt::println("strict digraph deps {")!;
		for (let i = 0z; i < len(visited); i += 1) {
			for (let j = 0z; j < len(visited[i].depends); j += 1) {
				const child = visited[visited[i].depends[j]];
				fmt::printfln("\t\"{}\" -> \"{}\";", visited[i].ident, child.ident)!;
			};
		};
		fmt::println("}")!;
	case deps_goal::MAKE =>
		abort("-M option not implemented yet");
	};
};

fn run(cmd: *getopt::command) void = {
	const build_target = default_target();
	let tags = module::tags_dup(build_target.tags);
	defer module::tags_free(tags);

	let verbose = false;
	let defines: []str = [];
	defer free(defines);
	let libdir: []str = [];
	defer free(libdir);
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
		case 'L' =>
			append(libdir, opt.1);
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

	const plan = mkplan(&ctx, libdir, libs, build_target);
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
		fmt::fatalf("{} run: build failed", os::args[0]);
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

fn test(cmd: *getopt::command) void = {
	const build_target = default_target();
	let tags = module::tags_dup(build_target.tags);
	append(tags, module::tag {
		name = strings::dup("test"),
		mode = module::tag_mode::INCLUSIVE,
	});

	let output = "";
	let verbose = false;
	let defines: []str = [];
	defer free(defines);
	let libdir: []str = [];
	defer free(libdir);
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
		case 'L' =>
			append(libdir, opt.1);
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

	if (len(libs) > 0) {
		append(tags, module::tag {
			mode = module::tag_mode::INCLUSIVE,
			name = strings::dup("libc"),
		});
	};

	const ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	const plan = mkplan(&ctx, libdir, libs, build_target);
	defer plan_finish(&plan);

	let depends: []*task = [];
	sched_module(&plan, ["test"], &depends);

	let items = match (module::walk(&ctx, ".")) {
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
		fmt::fatalf("{} test: build failed", os::args[0]);
	};

	if (have_output) {
		return;
	};

	const cmd = match (exec::cmd(output, cmd.args...)) {
	case let err: exec::error =>
		fmt::fatal("exec:", exec::strerror(err));
	case let cmd: exec::command =>
		yield cmd;
	};
	exec::setname(&cmd, os::getcwd());
	exec::exec(&cmd);
};

fn version(cmd: *getopt::command) void = {
	let verbose = false;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		// The only option is verbose
		verbose = true;
	};

	fmt::printfln("Hare {}", VERSION)!;

	if (verbose) {
		fmt::printf("Build tags\t")!;
		const build_target = default_target();
		const tags = build_target.tags;
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
