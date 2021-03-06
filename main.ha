use encoding::hex;
use fmt;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use strio;

export fn main() void = {
	if (len(os::args) == 1) {
		fmt::fatal("Usage: {} <path>", os::args[0]);
	};

	let ctx = module::context_init([module::tag{
		name = os::machine(),
		mode = module::tag_mode::INCLUSIVE,
	}]);
	let ver = match (module::scan(&ctx, os::args[1])) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};

	let plan = plan { ... };

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
					fmt::errorfln("\t{}",
						ver.inputs[i].path as str);
				};
			},
		};
	};

	let harec = alloc(task {
		status = status::SCHEDULED,
		inputs = ver.inputs,
		output = "hare.ssa",
		cmd = alloc(["harec"]),
		...
	});

	for (let i = 0z; i < len(ver.inputs); i += 1) {
		let path = ver.inputs[i].path as str;
		append(harec.cmd, path);
	};

	append(plan.scheduled, harec);

	for (len(plan.scheduled) != 0) {
		let next: nullable *task = null;
		let i = 0z;
		for (i < len(plan.scheduled); i += 1) {
			// TODO: Check dependencies and pick the next eligible
			// task instead
			next = plan.scheduled[i];
			break;
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

fn execute(
	ctx: *module::context,
	task: *task,
) (void | exec::error | exec::exit_status!) = {
	for (let i = 0z; i < len(task.cmd); i += 1) {
		fmt::errorf("{} ", task.cmd[i]);
	};
	fmt::errorln();

	let cmd = exec::cmd(task.cmd[0], task.cmd[1..]...)?;
	exec::setenv(&cmd, "HARECACHE", ctx.cache as str);

	let proc = exec::start(&cmd)?;
	let st = exec::wait(&proc)?;
	return exec::check(&st)?;
};
