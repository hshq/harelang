// The purpose of this file is to prepare a "build plan", which is then executed
// in queue.ha.
use hare::ast;
use hare::module2;
use hare::unparse;
use hash;
use hash::fnv;
use os;
use strings;
use fmt; // XXX: TEMP

type plan = struct {
	ctx: *module2::context,
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
};

type module = struct {
	hash: size,
	task: *task,
	ident: ast::ident,
	mod: *module2::module, // TODO: Free me
};

fn newplan(ctx: *module2::context) plan = plan {
	ctx = ctx,
	...
};

fn plan_finish(plan: *plan) void = {
	return; // TODO
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
	abort(); // TODO
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
