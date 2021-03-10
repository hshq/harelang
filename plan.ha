use fmt;
use hare::module;
use os::exec;
use os;
use path;
use strings;

type status = enum {
	SCHEDULED,
	COMPLETE,
};

type task = struct {
	status: status,
	depend: []*task,
	output: str,
	cmd: []str,
};

type plan = struct {
	workdir: str,
	counter: uint,
	scheduled: []*task,
	complete: []*task,
	script: str,
};

fn task_free(task: *task) void = {
	free(task.depend);
	free(task.output);
	free(task.cmd);
	free(task);
};

// Schedules a task which compiles objects into an executable.
fn sched_ld(plan: *plan, output: str, depend: *task...) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = mkdepends(depend...),
		cmd = alloc([
			os::tryenv("LD", "ld"),
			"-T", plan.script,
			"-o", output,
		]),
	});
	for (let i = 0z; i < len(depend); i += 1) {
		append(task.cmd, depend[i].output);
	};
	append(plan.scheduled, task);
	return task;
};

// Schedules a task which compiles assembly into an object.
fn sched_as(plan: *plan, output: str, depend: *task) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = mkdepends(depend),
		cmd = alloc([
			os::tryenv("AS", "as"), "-o", output, depend.output,
		]),
	});
	append(plan.scheduled, task);
	return task;
};

// Schedules a task which compiles an SSA file into assembly.
fn sched_qbe(plan: *plan, output: str, depend: *task) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = mkdepends(depend),
		cmd = alloc([
			os::tryenv("QBE", "qbe"), "-o", output, depend.output,
		]),
	});
	append(plan.scheduled, task);
	return task;
};

// Schedules tasks which compiles a Hare module into an object or archive.
fn sched_hare_object(
	plan: *plan,
	inputs: []module::input,
	output: str,
	depend: *task...
) *task = {
	// TODO: Handle mixed sources
	let ssa = mkfile(plan, "ssa");
	let s = mkfile(plan, "s");

	let harec = alloc(task {
		status = status::SCHEDULED,
		output = ssa,
		depend = mkdepends(depend...),
		cmd = alloc([
			os::tryenv("HAREC", "harec"), "-o", ssa,
		]),
	});

	for (let i = 0z; i < len(inputs); i += 1) {
		let path = inputs[i].path;
		append(harec.cmd, path);
	};
	append(plan.scheduled, harec);

	return sched_as(plan, output, sched_qbe(plan, s, harec));
};

// Schedules tasks which compiles hare sources into an executable.
fn sched_hare_exe(
	plan: *plan,
	inputs: []module::input,
	output: str,
	depend: *task...
) *task = {
	let o = sched_hare_object(plan, inputs, mkfile(plan, "o"), depend...);
	return sched_ld(plan, strings::dup(output), o);
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
	exec::setenv(&cmd, "HARECACHE", ctx.cache);

	let proc = exec::start(&cmd)?;
	let st = exec::wait(&proc)?;
	return exec::check(&st);
};

fn mkfile(plan: *plan, ext: str) str = {
	static let namebuf: [32]u8 = [0...];
	const name = fmt::bsprintf(namebuf, "temp.{}.{}",
		plan.counter, ext);
	plan.counter += 1;
	return path::join(plan.workdir, name);
};

fn mkdepends(t: *task...) []*task = {
	// XXX: This should just be one alloc call
	let deps: []*task = alloc([], len(t));
	append(deps, ...t);
	return deps;
};
