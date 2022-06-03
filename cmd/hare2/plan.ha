// The purpose of this file is to prepare a "build plan", which is then executed
// in queue.ha.
use encoding::hex;
use fmt;
use hare::ast;
use hare::module2;
use hare::unparse;
use hash::fnv;
use hash;
use os;
use path;
use shlex;
use strconv;
use strings;
use temp;

type plan = struct {
	ctx: *module2::context,
	workdir: str,
	serial: uint,
	schedule: []*task,
	complete: []*task,
	modcache: [64][]module,
};

type status = enum {
	SCHEDULED,
	COMPLETE,
};

type task = struct {
	status: status,
	depend: []*task,
	cmd: []str,
	output: str,
};

type module = struct {
	hash: size,
	task: *task,
	ident: ast::ident,
	mod: *module2::module, // TODO: Free me
};

fn newplan(ctx: *module2::context) plan = {
	return plan {
		ctx = ctx,
		// XXX: Would be nice to avoid using a temporary directory,
		// perhaps we can store intemediate artifacts in the cache?
		workdir = temp::dir(),
		...
	};
};

fn plan_finish(plan: *plan) void = {
	os::rmdirall(plan.workdir)!;
	// TODO: Free other stuff
};

fn sched_module(
	plan: *plan,
	mod: *module2::module,
) *task = {
	const hash = identhash(mod.ident);
	const bucket = &plan.modcache[hash % len(plan.modcache)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (hash == bucket[i].hash) {
			return bucket[i].task;
		};
	};

	let depends: []*task = [];
	for (let i = 0z; i < len(mod.depends); i += 1) {
		// TODO: Much of this code should go somewhere else imho
		const dep = mod.depends[i];
		const modpath = match (module2::resolve(plan.ctx, dep.ident)) {
		case let path: str =>
			yield path;
		case let err: module2::error =>
			modfatal(dep.ident, err);
		};
		const depmod = match (module2::scan(plan.ctx, dep.ident, modpath)) {
		case let mod: module2::module =>
			yield mod;
		case let err: module2::error =>
			modfatal(dep.ident, err);
		};
		const obj = sched_module(plan, &depmod);
		append(depends, obj);
	};
	defer free(depends);

	let obj = sched_hare_object(plan, mod, depends...);
	append(bucket, module {
		hash = hash,
		task = obj,
		ident = mod.ident,
		mod = mod,
	});
	return obj;
};

fn sched_hare_object(
	plan: *plan,
	mod: *module2::module,
	depends: []*task,
) *task = {
	const ssa = mktemp(plan, mod.ident, "ssa");

	let nasm = 0, nhare = 0;
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		if (strings::hassuffix(mod.inputs[i].path, ".s")) {
			nasm += 1;
		} else if (strings::hassuffix(mod.inputs[i].path, ".ha")) {
			nhare += 1;
		};
	};
	// XXX: Assembly-only modules have not been tested
	const mixed = nasm > 0 && nhare > 0;

	let cmd = mkcmd("HAREC", "harec", "-o", ssa);
	const ctx = plan.ctx;
	if (len(mod.ident) != 0) {
		const version = hex::encodestr(mod.cachekey);
		defer free(version);
		let uscoreid = module2::identuscore(mod.ident);
		defer free(uscoreid);

		append(harec.cmd, ["-N", unparse::identstr(mod.ident)]...);
		append(plan.environ, (
			fmt::asprintf("HARE_VERSION_{}", env), version,
		));

		let name = fmt::asprintf("{}.{}", version,
			if (mixed) "a" else "o");
		defer free(name);

		let path = path::init();
		path::set(&path, ctx.cache)!;
		module2::identpath(&path, mod.ident)!;
		path::add(&path, name);
	};


	let asinputs: []str = [];
	defer free(asinputs);
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		if (strings::hassuffix(mod.inputs[i].path, ".s")) {
			append(asinputs, mod.inputs[i].path);
		} else if (strings::hassuffix(mod.inputs[i].path, ".ha")) {
			append(cmd, strings::dup(mod.inputs[i].path));
		};
	};

	let harec = alloc(task {
		status = status::SCHEDULED,
		depend = alloc(depends...),
		cmd = cmd,
		output = output,
	});

	return harec;
};

fn mktemp(plan: *plan, ident: ast::ident, suffix: str) str = {
	const ident = module2::identuscore(ident);
	defer free(ident);
	let buf = path::init();
	const serial = strconv::utos(plan.serial);
	path::set(&buf, plan.workdir, ident, serial, suffix)!;
	plan.serial += 1;
	return strings::dup(path::string(&buf));
};

fn mkcmd(env: str, name: str, args: str...) []str = {
	const bin = os::tryenv(env, name);
	const flname = fmt::asprintf("{}FLAGS");
	defer free(flname);

	let argv: []str = [];
	match (os::getenv(flname)) {
	case void => yield;
	case let value: str =>
		match (shlex::split(value)) {
		case shlex::syntaxerr =>
			fmt::errorln("Ignoring {}: syntax error in shell parameters", flname)!;
		case let items: []str =>
			append(argv, items...);
		};
	};

	const dup = strings::dupall(args);
	defer free(dup);
	append(argv, dup...);
	return argv;
};

fn identhash(id: ast::ident) size = {
	let fnv = fnv::fnv64a();
	for (let i = 0z; i < len(id); i += 1) {
		hash::write(&fnv, strings::toutf8(id[i]));
		hash::write(&fnv, [0]);
	};
	return fnv::sum64(&fnv): size;
};

@noreturn fn modfatal(
	ident: ast::ident,
	err: module2::error,
) void = {
	const name = unparse::identstr(ident);
	defer free(name);
	fmt::fatal("Error resolving {}: {}", module2::strerror(err));
};
