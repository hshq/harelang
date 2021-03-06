use fmt;
use hare::module;
use os;
use os::exec;

type status = enum {
	SCHEDULED,
	COMPLETE,
};

type task = struct {
	status: status,
	inputs: []module::input,
	depend: []*task,
	output: path::path,
	cmd: []str,
};

type plan = struct {
	scheduled: []*task,
	complete: []*task,
};

fn sched_hare_exe(
	plan: *plan,
	inputs: []module::input,
	output: path::path,
	depend: []*task,
) *task = {
	// TODO: Schedule the qbe, as, and ld tasks
	let task = alloc(task {
		status = status::SCHEDULED,
		inputs = inputs,
		output = output,
		depend = depend,
		cmd = alloc([os::tryenv("HAREC", "harec"), "-o", output as str]),
	});
	for (let i = 0z; i < len(inputs); i += 1) {
		let path = inputs[i].path as str;
		append(task.cmd, path);
	};
	append(plan.scheduled, task);
	return task;
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
