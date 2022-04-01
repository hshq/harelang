// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use fmt;
use fs;
use hare::ast;
use hare::module;
use io;
use os::exec;
use os;
use path;
use strings;
use temp;
use unix::tty;

type status = enum {
	SCHEDULED,
	COMPLETE,
	SKIP,
};

type task = struct {
	status: status,
	depend: []*task,
	output: str,
	cmd: []str,
	module: (str | void),
};

fn task_free(task: *task) void = {
	free(task.depend);
	free(task.output);
	free(task.cmd);
	match (task.module) {
	case let s: str =>
		free(s);
	case => void;
	};
	free(task);
};

type modcache = struct {
	hash: u32,
	task: *task,
	ident: ast::ident,
	version: module::version,
};

type plan = struct {
	context: *module::context,
	workdir: str,
	counter: uint,
	scheduled: []*task,
	complete: []*task,
	script: str,
	libs: []str,
	environ: [](str, str),
	modmap: [64][]modcache,
	progress: plan_progress,
};

type plan_progress = struct {
	tty: (io::file | void),
	complete: size,
	total: size,
	current_module: str,
};

fn mkplan(ctx: *module::context, libs: []str) plan = {
	const rtdir = match (module::lookup(ctx, ["rt"])) {
	case let err: module::error =>
		fmt::fatal("Error resolving rt: {}", module::strerror(err));
	case let ver: module::version =>
		yield ver.basedir;
	};

	// Look up the most appropriate hare.sc file
	let ntag = 0z;
	const buf = path::init();
	const iter = os::iter(rtdir)!;
	defer os::finish(iter);
	for (true) match (fs::next(iter)) {
	case let d: fs::dirent =>
		const p = module::parse_name(d.name);
		const name = p.0, ext = p.1, tags = p.2;
		defer module::tags_free(tags);

		if (len(tags) >= ntag && name == "hare" && ext == ".sc"
				&& module::tagcompat(ctx.tags, tags)) {
			ntag = len(tags);
			path::set(&buf, rtdir, d.name)!;
		};
	case void =>
		break;
	};

	return plan {
		context = ctx,
		workdir = os::tryenv("HARE_DEBUG_WORKDIR", temp::dir()),
		script = path::allocate(&buf),
		environ = alloc([
			(strings::dup("HARECACHE"), strings::dup(ctx.cache)),
		]),
		libs = libs,
		progress = plan_progress {
			tty = if (tty::isatty(os::stderr)) os::stderr else void,
			...
		},
		...
	};
};

fn plan_finish(plan: *plan) void = {
	if (os::getenv("HARE_DEBUG_WORKDIR") is void) {
		os::rmdirall(plan.workdir)!;
	};

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

	free(plan.script);
	free(plan.libs);

	for (let i = 0z; i < len(plan.modmap); i += 1) {
		free(plan.modmap[i]);
	};
};

fn plan_execute(plan: *plan, verbose: bool) (void | !exec::exit_status) = {
	plan.progress.total = len(plan.scheduled);

	if (verbose) {
		plan.progress.tty = void;
		for (let i = 0z; i < len(plan.environ); i += 1) {
			// TODO: Uncomment this with shlex::quote
			let item = plan.environ[i];
			fmt::errorfln("# {}={}", item.0, item.1)!;
		};
	};

	for (len(plan.scheduled) != 0) {
		let next: nullable *task = null;
		let i = 0z;
		for (i < len(plan.scheduled); i += 1) {
			let task = plan.scheduled[i];
			let eligible = true;
			for (let j = 0z; j < len(task.depend); j += 1) {
				if (task.depend[j].status == status::SCHEDULED) {
					eligible = false;
					break;
				};
			};
			if (eligible) {
				next = task;
				break;
			};
		};

		let task = next as *task;
		match (task.module) {
		case let s: str =>
			plan.progress.current_module = s;
		case => void;
		};

		progress_increment(plan);

		match (execute(plan, task, verbose)) {
		case let err: exec::error =>
			progress_clear(plan);
			fmt::fatal("Error: {}: {}", task.cmd[0],
				exec::strerror(err));
		case let err: !exec::exit_status =>
			progress_clear(plan);
			fmt::errorfln("Error: {}: {}", task.cmd[0],
				exec::exitstr(err))!;
			return err;
		case void => void;
		};

		task.status = status::COMPLETE;

		delete(plan.scheduled[i]);
		append(plan.complete, task);
	};

	progress_clear(plan);
	update_modcache(plan);
};

fn update_cache(plan: *plan, mod: modcache) void = {
	let manifest = module::manifest {
		ident = mod.ident,
		inputs = mod.version.inputs,
		versions = [mod.version],
	};
	match (module::manifest_write(plan.context, &manifest)) {
	case let err: module::error =>
		fmt::fatal("Error updating module cache: {}",
			module::strerror(err));
	case void => void;
	};
};

fn update_modcache(plan: *plan) void = {
	for (let i = 0z; i < len(plan.modmap); i += 1) {
		let mods = plan.modmap[i];
		if (len(mods) == 0) {
			continue;
		};
		for (let j = 0z; j < len(mods); j += 1) {
			if (mods[j].task.status == status::COMPLETE) {
				update_cache(plan, mods[j]);
			};
		};
	};
};

fn execute(
	plan: *plan,
	task: *task,
	verbose: bool,
) (void | exec::error | !exec::exit_status) = {
	if (verbose) {
		for (let i = 0z; i < len(task.cmd); i += 1) {
			fmt::errorf("{} ", task.cmd[i])!;
		};
		fmt::errorln()!;
	};

	let cmd = exec::cmd(task.cmd[0], task.cmd[1..]...)!;
	for (let i = 0z; i < len(plan.environ); i += 1) {
		let e = plan.environ[i];
		exec::setenv(&cmd, e.0, e.1);
	};

	const pipe = if (plan.progress.tty is io::file) {
		const pipe = exec::pipe();
		exec::addfile(&cmd, os::stderr, pipe.1);
		yield pipe;
	} else (0: io::file, 0: io::file);

	let proc = exec::start(&cmd)?;
	if (pipe.0 != 0) {
		io::close(pipe.1);
	};

	let cleared = false;
	if (pipe.0 != 0) {
		for (true) {
			let buf: [os::BUFSIZ]u8 = [0...];
			match (io::read(pipe.0, buf)!) {
			case let n: size =>
				if (!cleared) {
					progress_clear(plan);
					cleared = true;
				};
				io::write(os::stderr, buf[..n])!;
			case io::EOF =>
				break;
			};
		};
	};
	let st = exec::wait(&proc)?;
	return exec::check(&st);
};

fn mkfile(plan: *plan, input: str, ext: str) str = {
	static let namebuf: [32]u8 = [0...];
	const name = fmt::bsprintf(namebuf, "temp.{}.{}.{}",
		input, plan.counter, ext);
	plan.counter += 1;
	return path::join(plan.workdir, name);
};
