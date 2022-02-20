use fmt;
use fs;
use hare::ast;
use hare::module;
use io;
use math;
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
		workdir = temp::dir(),
		script = path::allocate(&buf),
		environ = alloc([
			(strings::dup("HARECACHE"), strings::dup(ctx.cache)),
		]),
		libs = libs,
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
	if (verbose) {
		for (let i = 0z; i < len(plan.environ); i += 1) {
			// TODO: Uncomment this with shlex::quote
			let item = plan.environ[i];
			fmt::errorfln("# {}={}", item.0, item.1)!;
		};
	};

	let current_module = "";
	let current = 0z;
	const total = len(plan.scheduled);
	// Disable progress when used with -v
	const term = if (!verbose && tty::isatty(os::stderr)) {
		yield os::stderr;
	} else {
		yield;
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
		// TODO: This can be a type assertion
		let task = match (next) {
		case null =>
			abort();
		case let t: *task =>
			yield t;
		};

		match (task.module) {
		case let s: str =>
			current_module = s;
		case => void;
		};

		match (term) {
		case let term: io::file =>
			current += 1;
			fmt::fprintf(term, "\r\x1b[K[{%}/{}] [",
				current, &fmt::modifiers {
					width = math::ceilf64(math::log10f64(
						total: f64)): uint,
					...
				},
				total)!;
			const stop = (current: f64 / total: f64 * 50.0): size;
			for (let i = 0z; i < 50; i += 1) {
				if (i > stop) {
					fmt::fprint(term, ".")!;
				} else {
					fmt::fprint(term, "#")!;
				};
			};
			fmt::fprintf(term, "] {}", current_module)!;
		case => void;
		};

		match (execute(plan, task, verbose)) {
		case let err: exec::error =>
			fmt::fatal("Error: {}: {}", task.cmd[0],
				exec::strerror(err));
		case let err: !exec::exit_status =>
			fmt::errorfln("Error: {}: {}", task.cmd[0],
				exec::exitstr(err))!;
			return err;
		case void => void;
		};

		task.status = status::COMPLETE;

		delete(plan.scheduled[i]);
		append(plan.complete, task);
	};

	match (term) {
	case let term: io::file =>
		fmt::fprintln(term)!;
	case => void;
	};

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

	let cmd = exec::cmd(task.cmd[0], task.cmd[1..]...)?;
	for (let i = 0z; i < len(plan.environ); i += 1) {
		let e = plan.environ[i];
		exec::setenv(&cmd, e.0, e.1);
	};

	let proc = exec::start(&cmd)?;
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
