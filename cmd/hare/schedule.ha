// License: GPL-3.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use encoding::hex;
use fmt;
use fs;
use hare::ast;
use hare::module;
use hare::unparse;
use hash::fnv;
use hash;
use os;
use path;
use strings;
use strio;

fn ident_hash(ident: ast::ident) u32 = {
	let hash = fnv::fnv32();
	for (let i = 0z; i < len(ident); i += 1) {
		hash::write(&hash, strings::toutf8(ident[i]));
		hash::write(&hash, [0]);
	};
	return fnv::sum32(&hash);
};

fn sched_module(plan: *plan, ident: ast::ident, link: *[]*task) *task = {
	let hash = ident_hash(ident);
	let bucket = &plan.modmap[hash % len(plan.modmap)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].hash == hash) {
			return bucket[i].task;
		};
	};

	let ver = match (module::lookup(plan.context, ident)) {
	case let err: module::error =>
		let ident = unparse::identstr(ident);
		fmt::fatalf("Error resolving {}: {}", ident,
			module::strerror(err));
	case let ver: module::version =>
		yield ver;
	};

	let depends: []*task = [];
	defer free(depends);
	for (let i = 0z; i < len(ver.depends); i += 1) {
		const dep = ver.depends[i];
		let obj = sched_module(plan, dep, link);
		append(depends, obj);
	};

	let obj = sched_hare_object(plan, ver, ident, depends...);
	append(bucket, modcache {
		hash = hash,
		task = obj,
		ident = ident,
		version = ver,
	});
	append(link, obj);
	return obj;
};

// Schedules a task which compiles objects into an executable.
fn sched_ld(plan: *plan, output: str, depend: *task...) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = alloc(depend...),
		cmd = alloc([
			// C compiler is used as linker if we -l something
			os::tryenv("LD",
				if (len(plan.libs) > 0) "cc" else "ld"),
			"-T", plan.script,
			"-o", output,
		]),
		module = void,
	});

	// Using --gc-sections will not work when using cc as the linker
	if (len(plan.libs) == 0) {
		append(task.cmd, "--gc-sections");
	};

	let archives: []str = [];
	defer free(archives);

	for (let i = 0z; i < len(depend); i += 1) {
		if (strings::hassuffix(depend[i].output, ".a")) {
			append(archives, depend[i].output);
		} else {
			append(task.cmd, depend[i].output);
		};
	};
	append(task.cmd, archives...);
	for (let i = 0z; i < len(plan.libs); i += 1) {
		append(task.cmd, strings::concat("-l", plan.libs[i]));
	};
	append(plan.scheduled, task);
	return task;
};

// Schedules a task which merges objects into an archive.
fn sched_ar(plan: *plan, output: str, depend: *task...) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = alloc(depend...),
		cmd = alloc([
			os::tryenv("AR", "ar"), "-csr", output,
		]),
		module = void,
	});
	for (let i = 0z; i < len(depend); i += 1) {
		assert(strings::hassuffix(depend[i].output, ".o"));
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
		depend = alloc(depend...),
		cmd = alloc([
			os::tryenv("AS", "as"), "-g", "-o", output, input,
		]),
		module = void,
	});
	append(plan.scheduled, task);
	return task;
};

// Schedules a task which compiles an SSA file into assembly.
fn sched_qbe(plan: *plan, output: str, depend: *task) *task = {
	let task = alloc(task {
		status = status::SCHEDULED,
		output = output,
		depend = alloc([depend]),
		cmd = alloc([
			os::tryenv("QBE", "qbe"), "-o", output, depend.output,
		]),
		module = void,
	});
	append(plan.scheduled, task);
	return task;
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
		if (strings::hassuffix(ver.inputs[i].path, ".s")) {
			mixed = true;
			break;
		};
	};

	const ns = unparse::identstr(namespace);
	let ssa = mkfile(plan, ns, "ssa");
	let harec = alloc(task {
		status = status::SCHEDULED,
		output = ssa,
		depend = alloc(depend...),
		cmd = alloc([
			os::tryenv("HAREC", "harec"), "-o", ssa,
		]),
		module = strings::dup(ns),
	});

	for (let i = 0z; i < len(plan.context.tags); i += 1) {
		if (plan.context.tags[i].mode == module::tag_mode::INCLUSIVE
				&& plan.context.tags[i].name == "test") {
			const opaths = plan.context.paths;
			plan.context.paths = ["."];
			const ver = module::lookup(plan.context, namespace);
			if (ver is module::version) {
				append(harec.cmd, "-T");
			};
			plan.context.paths = opaths;
			break;
		};
	};

	let current = false;
	let output = if (len(namespace) != 0) {
		let version = hex::encodestr(ver.hash);
		let env = module::identuscore(namespace);
		defer free(env);

		append(harec.cmd, ["-N", ns]...);
		append(plan.environ, (
			fmt::asprintf("HARE_VERSION_{}", env), version,
		));

		// TODO: Keep this around and append new versions, rather than
		// overwriting with just the latest
		let manifest = match (module::manifest_load(
				plan.context, namespace)) {
		case let err: module::error =>
			fmt::fatalf("Error reading cache entry for {}: {}", ns,
				module::strerror(err));
		case let m: module::manifest =>
			yield m;
		};
		defer module::manifest_finish(&manifest);
		current = module::current(&manifest, &ver);

		let name = fmt::asprintf("{}.{}", version,
			if (mixed) "a" else "o");
		defer free(name);

		let td = fmt::asprintf("{}.td", version);
		defer free(td);

		let buf = path::init();
		path::set(&buf, plan.context.cache)!;
		path::add(&buf, namespace...)!;
		const path = path::string(&buf);
		match (os::mkdirs(path)) {
		case void => void;
		case let err: fs::error =>
			fmt::fatalf("Error: mkdirs {}: {}", path,
				fs::strerror(err));
		};
		append(harec.cmd, ["-t", path::join(path, td)]...);
		yield path::join(path, name);
	} else {
		// XXX: This is probably kind of dumb
		// It would be better to apply any defines which affect this
		// namespace instead
		for (let i = 0z; i < len(plan.context.defines); i += 1) {
			append(harec.cmd, ["-D", plan.context.defines[i]]...);
		};

		yield mkfile(plan, ns, "o"); // TODO: Should exes go in the cache?
	};

	for (let i = 0z; i < len(ver.inputs); i += 1) {
		let path = ver.inputs[i].path;
		if (strings::hassuffix(path, ".ha")) {
			append(harec.cmd, path);
		};
	};

	if (current) {
		harec.status = status::COMPLETE;
		harec.output = output;
		append(plan.complete, harec);
		return harec;
	} else {
		append(plan.scheduled, harec);
	};

	let s = mkfile(plan, ns, "s");
	let qbe = sched_qbe(plan, s, harec);
	let hare_obj = sched_as(plan,
		if (mixed) mkfile(plan, ns, "o") else output,
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
		if (!strings::hassuffix(path, ".s")) {
			continue;
		};
		append(objs, sched_as(plan, mkfile(plan, ns, "o"), path));
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
	append(link, obj);
	append(link, depend...);
	return sched_ld(plan, strings::dup(output), link...);
};
