// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use crypto::sha256;
use fmt;
use hare::ast;
use hare::module;
use hare::unparse;
use hash;
use io;
use memio;
use os;
use os::exec;
use path;
use shlex;
use strings;

// for use as a scratch buffer
let buf = path::buffer { ... };

fn get_deps(ctx: *context, t: *task) []str = {
	let mod = ctx.mods[t.idx];
	switch (t.kind) {
	case stage::TD => abort();
	case stage::SSA =>
		let deps = strings::dupall(mod.srcs.ha);
		for (let (dep_idx, _) .. mod.deps) {
			append(deps, get_cache(ctx, dep_idx, stage::TD)!);
		};
		return deps;
	case stage::S =>
		return alloc([get_cache(ctx, t.idx, stage::SSA)!]...);
	case stage::O =>
		let deps = strings::dupall(mod.srcs.s);
		append(deps, get_cache(ctx, t.idx, stage::S)!);
		return deps;
	case stage::BIN =>
		let deps: []str = [];
		for (let i = 0z; i < len(ctx.mods); i += 1) {
			let srcs = &ctx.mods[i].srcs;
			for (let j = 0z; j < len(srcs.sc); j += 1) {
				append(deps, strings::dup(srcs.sc[j]));
			};
			append(deps, get_cache(ctx, i, stage::O)!);
			for (let o .. srcs.o) {
				append(deps, strings::dup(o));
			};
		};
		return deps;
	};
};

// returns the arguments that don't depend on the result of the hash. these will
// be used to create the hash. see [[get_args]] for the arguments that depend
// on the result of the hash
fn get_flags(ctx: *context, t: *task) ([]str | error) = {
	let flags: []str = strings::dupall(ctx.platform.default_flags[t.kind]);

	let flags_env = switch (t.kind) {
	case stage::TD => abort();
	case stage::SSA =>
		yield "HARECFLAGS";
	case stage::S =>
		yield "QBEFLAGS";
	case stage::O =>
		yield "ASFLAGS";
	case stage::BIN =>
		yield if (ctx.libc) "LDFLAGS" else "LDLINKFLAGS";
	};
	match (shlex::split(os::tryenv(flags_env, ""))) {
	case let s: []str =>
		append(flags, s...);
	case shlex::syntaxerr =>
		fmt::errorfln("warning: invalid shell syntax in ${}; ignoring",
			flags_env)?;
	};

	switch (t.kind) {
	case stage::TD => abort();
	case stage::SSA => void; // below
	case stage::S =>
		append(flags, strings::dup("-t"));
		append(flags, strings::dup(ctx.arch.qbe_name));
		return flags;
	case stage::O =>
		return flags;
	case stage::BIN =>
		for (let libdir .. ctx.libdirs) {
			append(flags, strings::dup("-L"));
			append(flags, strings::dup(libdir));
		};
		if (ctx.libc) {
			append(flags, strings::dup("-Wl,--gc-sections"));
		} else {
			append(flags, strings::dup("--gc-sections"));
			append(flags, strings::dup("-z"));
			append(flags, strings::dup("noexecstack"));
		};
		return flags;
	};

	append(flags, strings::dup("-a"));
	append(flags, strings::dup(ctx.arch.name));

	let mod = ctx.mods[t.idx];
	if (len(ctx.ns) != 0 && t.idx == ctx.top) {
		append(flags, strings::dup("-N"));
		append(flags, unparse::identstr(ctx.ns));
	} else if (len(mod.ns) != 0 || ctx.libc) {
		append(flags, strings::dup("-N"));
		append(flags, unparse::identstr(mod.ns));
	};
	if (ctx.freestanding) {
		append(flags, strings::dup("-m"));
		append(flags, "");
	} else if (ctx.libc) {
		append(flags, strings::dup("-m.main"));
	};
	append(flags, strings::dup("-M"));
	path::set(&buf, mod.path)?;
	for (let i = 0z; i < len(mod.ns); i += 1) {
		path::pop(&buf);
	};
	append(flags, strings::concat(path::string(&buf), "/"));

	path::set(&buf, mod.path)?;
	let test = ctx.test && t.idx == ctx.top;
	test ||= path::trimprefix(&buf, os::getcwd()) is str && ctx.submods;
	if (test) {
		append(flags, strings::dup("-T"));
	};

	for (let define .. ctx.defines) {
		let ident = define.ident;
		let ns = ident[..len(ident) - 1];
		if (!ast::ident_eq(ns, mod.ns)) {
			continue;
		};
		let buf = memio::dynamic();
		memio::concat(&buf, "-D", ident[len(ident) - 1])!;
		match (define._type) {
		case null => void;
		case let t: *ast::_type =>
			memio::concat(&buf, ":")!;
			unparse::_type(&buf, &unparse::syn_nowrap, t)!;
		};
		memio::concat(&buf, "=")!;
		unparse::expr(&buf, &unparse::syn_nowrap, define.init)!;
		append(flags, memio::string(&buf)!);
	};

	return flags;
};

fn get_hash(
	ctx: *context,
	deps: []str,
	flags: []str,
	t: *task,
) [sha256::SZ]u8 = {
	let h = sha256::sha256();

	hash::write(&h, ctx.cmd_hashes[t.kind]);
	for (let flag .. flags) {
		hash::write(&h, strings::toutf8(flag));
	};

	switch (t.kind) {
	case stage::TD => abort();
	case stage::SSA =>
		for (let dep .. ctx.mods[t.idx].deps) {
			let ns = unparse::identstr(dep.1);
			defer free(ns);
			let var = strings::concat("HARE_TD_", ns);
			defer free(var);
			let path = match (os::getenv(var)) {
			case void =>
				continue;
			case let path: str =>
				yield path;
			};
			hash::write(&h, strings::toutf8(var));
			hash::write(&h, strings::toutf8("="));
			hash::write(&h, strings::toutf8(path));
			hash::write(&h, [0]);
		};
	case stage::S => void;
	case stage::O => void;
	case stage::BIN =>
		for (let lib .. ctx.libs) {
			hash::write(&h, strings::toutf8(lib));
			hash::write(&h, [0]);
		};
	};

	for (let dep .. deps) {
		hash::write(&h, strings::toutf8(dep));
		hash::write(&h, [0]);
	};

	let prefix: [sha256::SZ]u8 = [0...];
	hash::sum(&h, prefix);
	return prefix;
};

// returns the value of flags plus the arguments that depend on the result of
// the hash. see [[get_flags]] for the arguments that don't depend on the hash
fn get_args(ctx: *context, tmp: str, flags: []str, t: *task) []str = {
	let args = strings::dupall(flags);
	append(args, strings::dup("-o"));
	append(args, strings::dup(tmp));

	// TODO: https://todo.sr.ht/~sircmpwn/hare/837
	let srcs: []str = switch (t.kind) {
	case stage::TD => abort();
	case stage::SSA =>
		let td = get_cache(ctx, t.idx, stage::SSA)!;
		defer free(td);
		append(args, strings::dup("-t"));
		append(args, strings::concat(td, ".td.tmp"));
		yield ctx.mods[t.idx].srcs.ha;
	case stage::S =>
		append(args, get_cache(ctx, t.idx, stage::SSA)!);
		yield [];
	case stage::O =>
		append(args, get_cache(ctx, t.idx, stage::S)!);
		yield ctx.mods[t.idx].srcs.s;
	case stage::BIN =>
		for (let i = 0z; i < len(ctx.mods); i += 1) {
			let srcs = ctx.mods[i].srcs;
			for (let sc .. srcs.sc) {
				append(args, strings::dup("-T"));
				append(args, strings::dup(sc));
			};
			append(args, get_cache(ctx, i, stage::O)!);
			for (let o .. srcs.o) {
				append(args, strings::dup(o));
			};
		};
		// XXX: when dynamically linking on Linux, we have to disable
		// gc-sections again after enabling it in get_flags(); it looks
		// like leaving this enabled gets us SIGILL in libc (musl). this
		// is not broken on other platforms such as OpenBSD
		if (ctx.libc) {
			append(args, strings::dup("-Wl,--no-gc-sections"));
		};
		for (let lib .. ctx.libs) {
			append(args, strings::dup("-l"));
			append(args, strings::dup(lib));
		};
		yield [];
	};
	for (let src .. srcs) {
		append(args, strings::dup(src));
	};
	return args;
};
