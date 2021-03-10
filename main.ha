use encoding::hex;
use fmt;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use path;
use strio;
use temp;

export fn main() void = {
	if (len(os::args) == 1) {
		fmt::fatal("Usage: {} <path>", os::args[0]);
	};

	let plan = plan {
		workdir = temp::dir(),
		...
	};
	defer os::rmdirall(plan.workdir);
	let ctx = module::context_init([module::tag {
		name = os::machine(),
		mode = module::tag_mode::INCLUSIVE,
	}, module::tag {
		// TEMP:
		name = "linux",
		mode = module::tag_mode::INCLUSIVE,
	}]);

	const rtdir = match (module::lookup(&ctx, ["rt"])) {
		err: module::error => fmt::fatal("Error resolving rt: {}",
			module::errstr(err)),
		ver: module::version => ver.basedir,
	};
	plan.script = path::join(rtdir, "hare.sc");

	let ver = match (module::scan(&ctx, os::args[1])) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};

	for (let i = 0z; i < len(ver.depends); i += 1z) {
		const dep = ver.depends[i];
		let ident = ast::ident_unparse_s(dep);
		defer free(ident);
		match (module::lookup(&ctx, dep)) {
			err: module::error => fmt::fatal("Error resolving {}: {}",
				ident, module::errstr(err)),
			ver: module::version => {
				let hash = hex::encode(ver.hash);
				defer free(hash);
				fmt::errorfln("{}: selecting version {}",
					ident, hash);
				for (let i = 0z; i < len(ver.inputs); i += 1) {
					fmt::errorfln("\t{}", ver.inputs[i].path);
				};
			},
		};
	};

	// TODO: Choose less stupid output name
	sched_hare_exe(&plan, ver.inputs, "a.out");

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

		match (execute(&ctx, task)) {
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
