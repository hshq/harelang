use encoding::hex;
use fmt;
use getopt;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use path;
use strio;
use temp;

type goal = enum {
	// Print dependency graph
	DEP,
	// Build executable
	EXE,
	// Build object
	OBJ,
	// Run program
	RUN,
	// Run tests
	TEST,
};

export fn main() void = {
	let verbose = false, goal = goal::EXE;
	let output = "";

	let help: []getopt::help = [
		"compile, run, and test Hare programs",
		('c', "produce an object instead of an executable"),
		('u', "print dependency graph"),
		('v', "enable verbose logging"),
		('D', "ident:type=value", "define a constant"),
		('l', "name", "link with a system library"),
		('o', "path", "set output path"),
		('t', "arch", "set target architecture"),
		('T', "tags...", "set build tags"),
		('X', "tags...", "unset build tags"),
		"subcommand", "args..."
	];
	let cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		let opt = cmd.opts[i];
		switch (opt.0) {
			'c' => goal = goal::OBJ,
			'u' => goal = goal::DEP,
			'v' => verbose = true,
			'D' => abort(), // TODO
			'l' => abort(), // TODO
			'o' => output = opt.1 as getopt::parameter,
			't' => abort(), // TODO
			'T' => abort(), // TODO
			'X' => abort(), // TODO
		};
	};

	if (len(cmd.args) < 1) {
		getopt::print_usage(os::stderr, os::args[0], help...);
		os::exit(1);
	};
	let newgoal =
		if (cmd.args[0] == "build") goal::EXE
		else if (cmd.args[0] == "run") {
			if (output != "") {
				fmt::fatal("Cannot combine -o and run command");
			};
			goal::RUN;
		}
		else if (cmd.args[0] == "test") goal::TEST
		else if (cmd.args[0] == "version") abort() // TODO
		else {
			getopt::print_usage(os::stderr, os::args[0], help...);
			os::exit(1);
		};
	if (goal != goal::DEP && goal != goal::OBJ) {
		newgoal = goal;
	};
	cmd.args = cmd.args[1..];

	let input = if (len(cmd.args) == 0) {
		os::getcwd();
	} else {
		assert(len(cmd.args) == 1); // TODO?
		cmd.args[0];
	};

	let plan = plan {
		workdir = temp::dir(),
		...
	};
	defer {
		os::rmdirall(plan.workdir);
		free(plan.workdir);

		for (let i = 0z; i < len(plan.complete); i += 1) {
			let task = plan.complete[i];
			task_free(task);
		};

		free(plan.scheduled);
		free(plan.complete);
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

	const rtdir = match (module::lookup(&ctx, ["rt"])) {
		err: module::error => fmt::fatal("Error resolving rt: {}",
			module::errstr(err)),
		ver: module::version => ver.basedir,
	};
	plan.script = path::join(rtdir, "hare.sc");

	let ver = match (module::scan(&ctx, input)) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};

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
				// TODO:
				// - Use the cache
				// - Transitive dependencies
				let obj = sched_hare_object(&plan,
					ver.inputs, ns);
				append(depends, obj);
			},
		};
	};

	if (output == "") {
		output = path::basename(os::resolve(ver.basedir));
	};
	sched_hare_exe(&plan, ver.inputs, output, depends...);

	for (len(plan.scheduled) != 0) {
		let next: nullable *task = null;
		let i = 0z;
		for (i < len(plan.scheduled); i += 1) {
			let task = plan.scheduled[i];
			let eligible = true;
			for (let j = 0z; j < len(task.depend); j += 1) {
				if (task.depend[j].status != status::COMPLETE) {
					eligible = false;
					break;
				};
			};
			if (eligible) {
				next = task;
				break;
			};
		};
		// TODO: This can be a type assertion
		let task = match (next) {
			null => abort(),
			t: *task => t,
		};

		match (execute(&ctx, task, verbose)) {
			err: exec::error => fmt::fatal("Error: {}: {}",
				task.cmd[0], exec::errstr(err)),
			err: exec::exit_status! => fmt::fatal("Error: {}: {}",
				task.cmd[0], exec::exitstr(err)),
			void => void,
		};

		task.status = status::COMPLETE;

		delete(plan.scheduled[i]);
		append(plan.complete, task);
	};
};
