use fmt;
use hare::ast;
use hare::module;
use hash::fnv;
use hash;
use os::exec;
use os;
use path;
use strings;
use temp;

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

fn task_free(task: *task) void = {
	free(task.depend);
	free(task.output);
	free(task.cmd);
	free(task);
};

type plan = struct {
	workdir: str,
	counter: uint,
	scheduled: []*task,
	complete: []*task,
	script: str,
	modset: [64][]u32,
};

fn mkplan(ctx: *module::context) plan = {
	const rtdir = match (module::lookup(ctx, ["rt"])) {
		err: module::error => fmt::fatal("Error resolving rt: {}",
			module::errstr(err)),
		ver: module::version => ver.basedir,
	};
	return plan {
		workdir = temp::dir(),
		script = path::join(rtdir, "hare.sc"),
		...
	};
};

fn plan_finish(plan: *plan) void = {
	os::rmdirall(plan.workdir);
	free(plan.workdir);

	for (let i = 0z; i < len(plan.complete); i += 1) {
		let task = plan.complete[i];
		task_free(task);
	};
	free(plan.complete);

	for (let i = 0z; i < len(plan.scheduled); i += 1) {
		let task = plan.scheduled[i];
		task_free(task);
	};
	free(plan.scheduled);

	for (let i = 0z; i < len(plan.modset); i += 1) {
		free(plan.modset[i]);
	};
};

fn ident_hash(ident: ast::ident) u32 = {
	let hash = fnv::fnv32();
	defer hash::close(hash);
	for (let i = 0z; i < len(ident); i += 1) {
		hash::write(hash, strings::to_utf8(ident[i]));
		hash::write(hash, [0]);
	};
	return fnv::sum32(hash);
};

fn sched_module(
	plan: *plan,
	ctx: *module::context,
	depends: *[]*task,
	ident: ast::ident,
) void = {
	let hash = ident_hash(ident);
	// TODO: We should not have to dereference the bucket
	// TODO: We should not have to cast the length
	let bucket = &plan.modset[hash % len(plan.modset): u32];
	for (let i = 0z; i < len(*bucket); i += 1) {
		if (bucket[i] == hash) {
			fmt::println("mod cache hit");
			return;
		};
	};
	fmt::println("mod cache miss");
	append(*bucket, hash);

	let ver = match (module::lookup(ctx, ident)) {
		err: module::error => {
			let ident = ast::ident_unparse_s(ident);
			fmt::fatal("Error resolving {}: {}",
				ident, module::errstr(err));
		},
		ver: module::version => ver,
	};
	let ns = ast::ident_unparse_s(ident);
	let obj = sched_hare_object(plan, ver.inputs, ns);
	// TODO: Unnecessary dereference
	append(*depends, obj);
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

// Schedules a task which merges objects into an archive.
fn sched_ar(plan: *plan, output: str, depend: *task...) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = mkdepends(depend...),
		cmd = alloc([
			os::tryenv("AR", "ar"), "-csr", output,
		]),
	});
	for (let i = 0z; i < len(depend); i += 1) {
		assert(strings::has_suffix(depend[i].output, ".o"));
		append(task.cmd, depend[i].output);
	};
	append(plan.scheduled, task);
	return task;
};

// Schedules a task which compiles assembly into an object.
fn sched_as(plan: *plan, output: str, input: str, depend: *task...) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = mkdepends(depend...),
		cmd = alloc([
			os::tryenv("AS", "as"), "-o", output, input,
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
// Returns the output path, generated as an object or archive name.
//
// Takes ownership over namespace, if provided.
fn sched_hare_object(
	plan: *plan,
	inputs: []module::input,
	namespace: (str | void),
	depend: *task...
) *task = {
	// XXX: Do we care to support assembly-only modules?
	let mixed = false;
	for (let i = 0z; i < len(inputs); i += 1) {
		if (strings::has_suffix(inputs[i].path, ".s")) {
			mixed = true;
			break;
		};
	};

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
	match (namespace) {
		void => void,
		ns: str => append(harec.cmd, "-N", ns),
	};

	for (let i = 0z; i < len(inputs); i += 1) {
		let path = inputs[i].path;
		if (strings::has_suffix(path, ".ha")) {
			append(harec.cmd, path);
		};
	};
	append(plan.scheduled, harec);

	let as_out = mkfile(plan, "o");
	let qbe = sched_qbe(plan, s, harec);
	let hare_obj = sched_as(plan, as_out, s, qbe);
	if (!mixed) {
		return hare_obj;
	};

	let objs: []*task = alloc([hare_obj]);
	defer free(objs);
	for (let i = 0z; i < len(inputs); i += 1) {
		// XXX: All of our assembly files don't depend on anything else,
		// but that may not be generally true. We may have to address
		// this at some point.
		let path = inputs[i].path;
		if (!strings::has_suffix(path, ".s")) {
			continue;
		};
		append(objs, sched_as(plan, mkfile(plan, "o"), path));
	};
	return sched_ar(plan, mkfile(plan, "a"), objs...);
};

// Schedules tasks which compiles hare sources into an executable.
fn sched_hare_exe(
	plan: *plan,
	inputs: []module::input,
	output: str,
	depend: *task...
) *task = {
	let obj = sched_hare_object(plan, inputs, void, depend...);
	// TODO: We should be able to use partial variadic application
	let link: []*task = alloc([], len(depend));
	defer free(link);
	append(link, obj, ...depend);
	return sched_ld(plan, strings::dup(output), link...);
};

fn execute(
	ctx: *module::context,
	task: *task,
	verbose: bool,
) (void | exec::error | exec::exit_status!) = {
	if (verbose) {
		for (let i = 0z; i < len(task.cmd); i += 1) {
			fmt::errorf("{} ", task.cmd[i]);
		};
		fmt::errorln();
	};

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

fn plan_execute(ctx: *module::context, plan: *plan, verbose: bool) void = {
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

		match (execute(ctx, task, verbose)) {
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
