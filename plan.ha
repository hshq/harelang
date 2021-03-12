use encoding::hex;
use fmt;
use hare::ast;
use hare::module;
use hash::fnv;
use hash;
use os::exec;
use os;
use path;
use strings;
use strio;
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

type modcache = struct {
	hash: u32,
	task: *task,
};

type plan = struct {
	context: *module::context,
	workdir: str,
	counter: uint,
	scheduled: []*task,
	complete: []*task,
	script: str,
	environ: [](str, str),
	modmap: [64][]modcache,
};

fn mkplan(ctx: *module::context) plan = {
	const rtdir = match (module::lookup(ctx, ["rt"])) {
		err: module::error => fmt::fatal("Error resolving rt: {}",
			module::errstr(err)),
		ver: module::version => ver.basedir,
	};
	return plan {
		context = ctx,
		workdir = temp::dir(),
		script = path::join(rtdir, "hare.sc"),
		environ = alloc([
			(strings::dup("HARECACHE"), strings::dup(ctx.cache)),
		]),
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

	for (let i = 0z; i < len(plan.environ); i += 1) {
		free(plan.environ[i].0);
		free(plan.environ[i].1);
	};
	free(plan.environ);

	for (let i = 0z; i < len(plan.modmap); i += 1) {
		free(plan.modmap[i]);
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

fn sched_module(plan: *plan, ident: ast::ident) *task = {
	let hash = ident_hash(ident);
	// TODO: We should not have to dereference the bucket for len or append
	// TODO: We should not have to cast the length to u32
	let bucket = &plan.modmap[hash % len(plan.modmap): u32];
	for (let i = 0z; i < len(*bucket); i += 1) {
		if (bucket[i].hash == hash) {
			return bucket[i].task;
		};
	};

	let ver = match (module::lookup(plan.context, ident)) {
		err: module::error => {
			let ident = ast::ident_unparse_s(ident);
			fmt::fatal("Error resolving {}: {}",
				ident, module::errstr(err));
		},
		ver: module::version => ver,
	};

	let depends: []*task = [];
	for (let i = 0z; i < len(ver.depends); i += 1) {
		const dep = ver.depends[i];
		let obj = sched_module(plan, dep);
		append(depends, obj);
	};

	let obj = sched_hare_object(plan, ver, ident, depends...);
	append(*bucket, modcache { hash = hash, task = obj });
	free(depends);
	return obj;
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

export fn ident_to_env(ident: ast::ident) str = {
	let buf = strio::dynamic();
	for (let i = 0z; i < len(ident); i += 1) {
		fmt::fprintf(buf, "{}{}", ident[i],
			if (i + 1 < len(ident)) "_"
			else "") as size;
	};
	return strio::finish(buf);
};

// Schedules tasks which compiles a Hare module into an object or archive.
fn sched_hare_object(
	plan: *plan,
	ver: module::version,
	namespace: ast::ident,
	depend: *task...
) *task = {
	// XXX: Do we care to support assembly-only modules?
	let mixed = false;
	for (let i = 0z; i < len(ver.inputs); i += 1) {
		if (strings::has_suffix(ver.inputs[i].path, ".s")) {
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
	let output = if (len(namespace) != 0) {
		// TODO: consult/update cache manifest
		let version = hex::encode(ver.hash);
		let ns = ast::ident_unparse_s(namespace);
		let env = ident_to_env(namespace);
		defer free(env);

		append(harec.cmd, "-N", ns);
		append(plan.environ, (
			fmt::asprintf("HARE_VERSION_{}", env), version,
		));

		let name = fmt::asprintf("{}.{}", version,
			if (mixed) "a" else "o");
		defer free(name);

		let td = fmt::asprintf("{}.td", version);
		defer free(td);

		let path = plan.context.cache;
		for (let i = 0z; i < len(namespace); i += 1) {
			path = path::join(path, namespace[i]);
		};
		os::mkdirs(path);
		append(harec.cmd, "-t", path::join(path, td));
		path::join(path, name);
	} else mkfile(plan, "o"); // TODO: Should exes go in the cache?

	for (let i = 0z; i < len(ver.inputs); i += 1) {
		let path = ver.inputs[i].path;
		if (strings::has_suffix(path, ".ha")) {
			append(harec.cmd, path);
		};
	};
	append(plan.scheduled, harec);

	let qbe = sched_qbe(plan, s, harec);
	let hare_obj = sched_as(plan,
		if (mixed) mkfile(plan, "o") else output,
		s, qbe);
	if (!mixed) {
		return hare_obj;
	};

	let objs: []*task = alloc([hare_obj]);
	defer free(objs);
	for (let i = 0z; i < len(ver.inputs); i += 1) {
		// XXX: All of our assembly files don't depend on anything else,
		// but that may not be generally true. We may have to address
		// this at some point.
		let path = ver.inputs[i].path;
		if (!strings::has_suffix(path, ".s")) {
			continue;
		};
		append(objs, sched_as(plan, mkfile(plan, "o"), path));
	};
	return sched_ar(plan, output, objs...);
};

// Schedules tasks which compiles hare sources into an executable.
fn sched_hare_exe(
	plan: *plan,
	ver: module::version,
	output: str,
	depend: *task...
) *task = {
	let obj = sched_hare_object(plan, ver, [], depend...);
	// TODO: We should be able to use partial variadic application
	let link: []*task = alloc([], len(depend));
	defer free(link);
	append(link, obj, ...depend);
	return sched_ld(plan, strings::dup(output), link...);
};

fn plan_execute(plan: *plan, verbose: bool) void = {
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

		match (execute(plan, task, verbose)) {
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
	plan: *plan,
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
	for (let i = 0z; i < len(plan.environ); i += 1) {
		let e = plan.environ[i];
		exec::setenv(&cmd, e.0, e.1);
	};

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
