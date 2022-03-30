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
	mods: []*module,
	modcache: [64][]*module,
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
	ident: ast::ident,
	mod: module2::module,
	cache: []module2::module,
};

fn newplan(ctx: *module2::context) plan = plan {
	ctx = ctx,
	...
};

fn schedule(plan: *plan, ident: ast::ident) (*module | module2::error) = {
	fmt::println("schedule", unparse::identstr(ident))!;
	const hash = identhash(ident);
	const bucket = &plan.modcache[hash % len(plan.modcache)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (hash == bucket[i].hash) {
			return bucket[i];
		};
	};

	const ctx = plan.ctx;
	const path = module2::resolve(ctx, ident)?;
	defer free(path);
	const path = strings::dup(os::resolve(path));
	defer free(path);

	const cache = module2::load(ctx, ident)?;
	for (let i = 0z; i < len(cache); i += 1) {
		if (cache[i].base == path) {
			abort(); // TODO
		};
	};

	const mod = module2::scan(ctx, ident, path)?;
	const mod = alloc(module {
		cache = cache,
		hash = hash,
		ident = ident,
		mod = mod,
	});
	append(plan.mods, mod);
	append(bucket, mod);

	for (let i = 0z; i < len(mod.mod.depends); i += 1) {
		const dep = &mod.mod.depends[i];
		schedule(plan, dep.ident)?;
	};

	return mod;
};

fn identhash(id: ast::ident) size = {
	let fnv = fnv::fnv64a();
	for (let i = 0z; i < len(id); i += 1) {
		hash::write(&fnv, strings::toutf8(id[i]));
		hash::write(&fnv, [0]);
	};
	return fnv::sum64(&fnv): size;
};
