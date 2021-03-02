use fmt;
use hare::module;
use io;
use os::exec;
use os;

export fn main() void = {
	if (len(os::args) == 1) {
		fmt::fatal("Usage: {} <path>", os::args[0]);
	};

	let ctx = module::context_init([]);
	let ver = match (module::scan(&ctx, os::args[1])) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};

	let plan = plan { ... };

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

		let cmd = match (exec::cmd(task.cmd[0], task.cmd[1..]...)) {
			cmd: exec::command => cmd,
			err: exec::error => fmt::fatal("Error: exec {}: {}",
				task.cmd[0], exec::errstr(err)),
		};
		let proc = match (exec::start(&cmd)) {
			err: exec::error => fmt::fatal("Error: start {}: {}",
				task.cmd[0], exec::errstr(err)),
			proc: exec::process => proc,
		};
		match (exec::wait(&proc)) {
			err: exec::error => fmt::fatal("Error: wait {}: {}",
				task.cmd[0], exec::errstr(err)),
			st: exec::status => match (exec::check(&st)) {
				err: exec::exit_status! => {
					fmt::fatal("Error: {}: {}", task.cmd[0],
						exec::exitstr(err));
				},
				void => void,
			},
		};

		task.status = status::COMPLETE;
		delete(plan.scheduled[i]);
		append(plan.complete, task);
	};
};
