use ascii;
use encoding::utf8;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::module;
use os;
use os::exec;
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
	let help: []getopt::help = [
		"compiles Hare programs",
		('c', "build object instead of executable"),
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('o', "path", "set output file name"),
		('t', "arch", "set target architecture"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"path"
	];
	let cmd = getopt::parse(args, help...);
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

	let input =
		if (len(cmd.args) == 0) os::getcwd()
		else if (len(cmd.args) == 1) cmd.args[0]
		else {
			getopt::printusage(os::stderr, args[0], help...);
			os::exit(1);
		};

	let ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	let plan = mkplan(&ctx);
	defer plan_finish(&plan);

	let ver = match (module::scan(&ctx, input)) {
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

	// TODO: Choose this more intelligently
	if (output == "") {
		output = path::basename(ver.basedir);
	};
	sched_hare_exe(&plan, ver, output, depends...);
	plan_execute(&plan, verbose);
};

fn cache(args: []str) void = {
	let help: []getopt::help = [
		"manages the build cache",
		('c', "cleans the specified modules"),
		"modules...",
	];
	let cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	abort(); // TODO
};

fn deps(args: []str) void = {
	let help: []getopt::help = [
		"prints dependency information for Hare programs",
		('d', "print dot syntax for use with graphviz"),
		('M', "print rules for POSIX make"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"path",
	];
	let cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	abort(); // TODO
};

fn run(args: []str) void = {
	let help: []getopt::help = [
		"compiles and runs Hare programs",
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"path", "args...",
	];
	let cmd = getopt::parse(args, help...);
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

	let ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	let plan = mkplan(&ctx);
	defer plan_finish(&plan);

	let ver = match (module::scan(&ctx, input)) {
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

	let output = mkfile(&plan, "out");
	sched_hare_exe(&plan, ver, output, depends...);
	plan_execute(&plan, verbose);
	let cmd = match (exec::cmd(output, runargs...)) {
		err: exec::error => fmt::fatal("exec: {}", exec::strerror(err)),
		cmd: exec::command => cmd,
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn sched_walk(plan: *plan, ident: ast::ident, link: *[]*task) void = {
	const path = module::identpath(ident);
	let it = os::iter(path)?;
	free(path);
	:loop for (true) match (fs::next(it)) {
		ent: fs::dirent => {
			if (ent.name == "." || ent.name == "..") {
				continue;
			};
			if (ent.ftype & fs::mode::DIR != fs::mode::DIR) {
				continue;
			};
			let d = utf8::decode(ent.name);
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
	let help: []getopt::help = [
		"compiles and runs tests for Hare programs",
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('j', "jobs", "set parallelism for build"),
		('l', "name", "link with a system library"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"[tests...]"
	];
	let cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	let tags = default_tags();
	defer module::tags_free(tags);
	append(tags, module::tag {
		name = strings::dup("test"),
		mode = module::tag_mode::INCLUSIVE,
	});

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


	let ctx = module::context_init(tags, defines, HAREPATH);
	defer module::context_finish(&ctx);

	let plan = mkplan(&ctx);
	defer plan_finish(&plan);

	let ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal(
			"Error scanning input module: {}",
			module::strerror(err)),
	};

	let depends: []*task = [];
	sched_module(&plan, ["rt"], &depends);
	sched_walk(&plan, [], &depends);

	let output = mkfile(&plan, "out");
	sched_hare_exe(&plan, ver, strings::dup(output), depends...);
	plan_execute(&plan, verbose);
	let cmd = match (exec::cmd(output, runargs...)) {
		err: exec::error => fmt::fatal("exec: {}", exec::strerror(err)),
		cmd: exec::command => cmd,
	};
	exec::setname(&cmd, input);
	exec::exec(&cmd);
};

fn version(args: []str) void = {
	fmt::printfln("Hare version {}", VERSION)!;
	fmt::errorln()!;
	fmt::printf("Build tags\t")!;
	const tags = default_tags();
	for (let i = 0z; i < len(tags); i += 1) {
		const tag = tags[i];
		const inclusive = (tag.mode & module::tag_mode::INCLUSIVE) == module::tag_mode::INCLUSIVE;
		fmt::printf("{}{}", if (inclusive) '+' else '-', tag.name)!;
	};
	fmt::println()!;

	match (os::getenv("HAREPATH")) {
		void => fmt::printfln("HAREPATH\t{}", HAREPATH)!,
		s: str => fmt::printfln("HAREPATH\t{}\t(from environment)", s)!,
	};
	if (len(args) > 1 && args[1] == "-v") {
		fmt::errorln("
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠀⢀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠊⠀⠀⠁⠀⢱⢄⠀⠀⠀⣷⠓⠀⠌⠓⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠡⡀⢰⠛⠀⠀⠀⠀⠀⢡⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡰⠁⠀⠀⢠⢠⠀⡄⢴⢠⣦⠀⢁⢸⢸⠀⠀⠀⠀⠀⠀⢁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠀⠀⡀⢰⠈⠌⠀⠇⣹⡞⡟⠀⢸⢸⡏⠂⠀⠀⡄⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡄⠀⡒⠀⢴⠏⠄⠘⠁⣾⣿⡆⠀⣸⣷⢠⠀⠀⡀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⢡⠀⡀⢢⠁⢟⢡⣸⢹⡇⠀⢿⡆⡄⡀⠀⠁⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡐⠀⢌⡖⡐⠐⠀⢾⠂⣿⣿⡧⠀⢠⠗⡁⠁⠰⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⢘⢻⢠⣧⡆⡘⡐⣿⣽⣷⠀⢸⢸⠃⡀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡄⠀⠈⣏⢿⣿⡔⣼⣿⣿⣿⠀⠸⡿⡿⢷⢀⡄⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠠⢤⡶⠒⠞⠓⢱⠀⠀⠸⣿⣻⣿⠿⣯⠆⠀⠀⡠⠿⠷⠜⠎⠰⠰⡄⣀⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⠈⡠⠅⡢⠄⠌⠀⠦⠀⢀⢇⠀⠀⡙⡯⠋⠀⢀⠨⠒⠑⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠣⡂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣐⣄⢽⠿⡰⡍⠐⠈⠀⠀⠀⠀⠀⠈⠃⠈⢆⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⡀⠀⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠐⠶⠿⠫⠠⠀⡐⠀⠀⠀⠀⠀⠉⠀⠀⠀⠒⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣄⠀⠈⠱⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠐⠂⠒⠑⠂⠄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢤⡏⠀⠀⠀   ⢠⣾⣿⣿⣿⠶⣄⠀⠀⠀⠀⠀⠀⠊⠀⢸⣾⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣰⠂⠀⢔⣊⠉⠀⠒⠂⠀⠀⠀⠀⢤⡀⡀⠀⠐⠔⢒⠀⠂⠀⠀  ⢸⣿⣿⣿⣧⠀⣼⡀⠀⠀⠀⠀⠀⠀⠣⡀⠻⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢐⡂⠴⠀⡚⠛⠀⠀⠈⠀⠀⠀⠀⠀⠐⠢⠠⠀⠀⠀⢱⡦⠀⠂⠀⠀⠀⠀⢻⣿⣿⣿⣷⣿⡧⠀⠀⠀⠀⠀⠀⠠⠉⠐⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠄⠨⠍⠙⠷⠟⠀⠐⠀⠀⠀⠤⡀⠀⠀⠠⣌⡁⠀⠀⢠⡶⠀⢀⡂⠀⠀⠀⠈⠛⠻⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠫⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢐⣭⡁⠥⣀⠻⣿⡄⣅⣤⠀⠈⠌⡂⠀⠀⠀⢀⡒⠠⠀⠂⣰⣡⡀⠀⠀⠀⠀⠀⠀⡠⠀⢄⢀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⢢⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢱⣏⣹⣯⢗⡩⣥⠄⠘⢓⠩⡀⠁⠀⠀⡀⠀⠂⡐⠠⠀⠀⢘⡻⣼⠄⡀⠂⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⣤⣄⠀⢀⡤⠙⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢰⣺⣿⣾⣮⡷⣖⣿⠂⡂⢚⣽⠆⠨⠀⠫⠀⠀⠘⠈⢢⠘⠀⠰⡲⡫⢾⣴⣀⠀⠀⠀⠀⠀⠀⡀⣀⢀⢀⠀⠀⠀⠈⢻⣷⠟⠡⡘⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⡽⣾⣷⣶⣯⣾⢞⣿⡾⠊⣈⢄⡂⠀⠢⢀⠄⡄⠀⠀⠈⠰⡁⡀⡘⠱⣱⡟⣝⢷⣧⣆⡔⡄⡀⡈⠀⠀⠀⠈⠀⠀⡀⠸⣇⣴⠴⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⡿⢿⣿⣿⣿⣕⣺⣗⣴⡿⣿⣈⣴⢆⠁⠊⠔⡖⠀⠁⡂⠈⠬⣾⣶⢹⣾⣮⣿⣿⣿⢿⣷⣷⣷⣦⣧⣶⣴⣧⣼⣷⣿⣿⢿⡗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⠀⠀⠤⠄⢪⢿⣿⣿⣿⣯⣗⡽⢻⣍⡿⣯⠱⣣⡢⢂⢈⠚⠠⠐⢐⠡⢀⢌⠋⢀⣿⡏⠹⣿⣿⣷⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣾⠿⠅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠐⠂⣀⣀⣀⠜⣯⣿⢿⣵⣿⣿⣭⡾⣙⠼⣼⡆⡄⣤⡏⠈⠈⠠⠞⠔⡈⠨⡀⠠⡼⣎⡀⣳⢘⣿⣽⣿⣿⣿⣿⣟⣿⣯⣻⣿⣼⣮⣿⡍⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠤⠀⠉⠙⠃⠸⣵⣿⣿⣿⣿⣭⣴⣷⣞⢍⠰⣅⡛⡿⣷⣈⡟⢓⣔⠁⡇⣣⣟⠆⣿⡼⣤⣤⣻⣨⣿⣿⣿⣿⣿⣿⣿⣿⣿⣻⣾⠯⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠐⠶⢘⢿⣿⣿⣿⣿⣿⣎⣯⡞⣾⣧⣟⣧⣿⡽⡹⢻⢠⢠⣤⣿⠻⠿⢻⠿⣾⣿⣿⣿⣷⣿⣟⣿⣿⣿⣿⣿⣿⡿⢏⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⣡⡭⣭⣉⣉⣈⠹⢿⣿⣿⣿⣾⣼⣿⣾⣷⣿⡿⢿⣿⣿⢿⣿⣾⣿⣿⣿⢷⣿⣄⣿⣬⣭⡜⡿⡟⢻⣿⣟⣿⣿⠿⡟⠜⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠤⠌⠭⠭⢭⢭⣥⣘⣻⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣷⣷⣹⣧⣧⣽⣿⣿⣿⡿⢟⣃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠐⠒⢒⣒⣀⣈⣉⣉⣋⣙⡻⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡿⣿⢿⢿⣿⠿⠻⠛⠯⠹⠁⢑⠐⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣀⣈⣀⣒⣓⡒⡒⠒⠒⢒⡀⠀⠀⠀⠀⠴⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠁⠀⣀⠀⠀⠤⠀⠤⠤⠀⠀⠒⠒⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠄⠀⠀⠀⠐⠒⠒⠒⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁")!;
	};
};
