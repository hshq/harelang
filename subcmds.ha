use fmt;
use getopt;
use hare::ast;
use hare::module;
use os;
use path;

fn build(args: []str) void = {
	let help: []getopt::help = [
		"compiles Hare programs",
		('c', "build object instead of executable"),
		('v', "print executed commands"),
		('D', "ident:type=value", "define a constant"),
		('l', "name", "link with a system library"),
		('o', "path", "set output file name"),
		('t', "arch", "set target architecture"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"<path | files...>"
	];
	let cmd = getopt::parse(args, help...);
	defer getopt::finish(&cmd);

	let verbose = false;
	let output = "";
	let goal = goal::EXE;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'c' => goal::OBJ,
			'v' => verbose = true,
			'D' => abort(), // TODO
			'l' => abort(), // TODO
			'o' => output = opt.1 as getopt::parameter,
			't' => abort(), // TODO
			'T' => abort(), // TODO
			'X' => abort(), // TODO
		};
	};

	assert(goal == goal::EXE); // TODO

	let input = if (len(cmd.args) == 0) os::getcwd() else {
		assert(len(cmd.args) == 1); // TODO?
		cmd.args[0];
	};

	let ctx = module::context_init([module::tag {
		name = os::machine(),
		mode = module::tag_mode::INCLUSIVE,
	}, module::tag {
		// TEMP:
		name = "linux",
		mode = module::tag_mode::INCLUSIVE,
	}]);
	defer module::context_finish(&ctx);

	let plan = mkplan(&ctx);
	defer plan_finish(&plan);

	let ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};

	// TODO:
	// - Use the hare cache
	// - Transitive dependencies
	// - Move this into a separate function, e.g. plan_module
	let depends: []*task = [];
	for (let i = 0z; i < len(ver.depends); i += 1z) {
		const dep = ver.depends[i];
		match (module::lookup(&ctx, dep)) {
			err: module::error => {
				let ident = ast::ident_unparse_s(dep);
				fmt::fatal("Error resolving {}: {}",
					ident, module::errstr(err));
			},
			ver: module::version => {
				let ns = ast::ident_unparse_s(dep);
				let obj = sched_hare_object(
					&plan, ver.inputs, ns);
				append(depends, obj);
			},
		};
	};

	if (output == "") {
		output = path::basename(ver.basedir);
	};
	sched_hare_exe(&plan, ver.inputs, output, depends...);
	plan_execute(&ctx, &plan, verbose);
};

fn run(args: []str) void = {
	abort(); // TODO
};

fn test(args: []str) void = {
	abort(); // TODO
};

fn version(args: []str) void = {
	abort(); // TODO
};
