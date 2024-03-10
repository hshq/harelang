// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::unparse;
use io;
use memio;
use os;
use path;
use sort;
use strings;

// A hare module.
export type module = struct {
	name: str,
	ns: ast::ident,
	path: str,
	srcs: srcset,
	// [](Index to the module, Identifier of of the module)
	deps: [](size, ast::ident),
};

// Get the list of dependencies referred to by a set of source files.
// The list will be sorted alphabetically and deduplicated.
export fn parse_deps(files: str...) ([]ast::ident | error) = {
	let deps: []ast::ident = [];
	for (let file .. files) {
		let handle = match (os::open(file)) {
		case let f: io::file =>
			yield f;
		case let e: fs::error =>
			return attach(strings::dup(file), e);
		};
		defer io::close(handle)!;

		let sc = bufio::newscanner(handle);
		defer bufio::finish(&sc);
		let lexer = lex::init(&sc, file);
		let imports = parse::imports(&lexer)?;
		defer ast::imports_finish(imports);

		// dedupe + insertion sort
		for (let import &.. imports) {
			let id = import.ident;
			let idx = sort::rbisect(deps, size(ast::ident), &id, &idcmp);
			if (idx == 0 || idcmp(&deps[idx - 1], &id) != 0) {
				insert(deps[idx], ast::ident_dup(id));
			};
		};
	};
	return deps;
};

fn idcmp(a: const *opaque, b: const *opaque) int = {
	const a = a: const *ast::ident, b = b: const *ast::ident;
	for (let i = 0z; i < len(a) && i < len(b); i += 1) {
		let cmp = strings::compare(a[i], b[i]);
		if (cmp != 0) {
			return cmp;
		};
	};
	if (len(a) < len(b)) {
		return -1;
	} else if (len(a) == len(b)) {
		return 0;
	} else {
		return 1;
	};
};

// Get the dependencies for a module from the cache, recalculating
// them if necessary. cachedir should be calculated with [[get_cache]],
// and srcset should be calculated with [[find]].
fn get_deps(cachedir: str, srcs: *srcset) ([]ast::ident | error) = {
	static let buf = path::buffer{...};
	path::set(&buf, cachedir, "deps")?;
	let rest = memio::fixed(buf.buf[buf.end..]);
	buf.end += format_tags(&rest, srcs.seentags)?;
	buf.end += memio::concat(&rest, ".txt")?;

	let outofdate = outdated(path::string(&buf), srcs.ha, srcs.mtime);
	os::mkdirs(cachedir, 0o755)?;
	let depsfile = os::create(path::string(&buf), 0o644, fs::flag::RDWR)?;
	defer io::close(depsfile)!;
	io::lock(depsfile, true, io::lockop::EXCLUSIVE)?;

	let deps: []ast::ident = [];
	if (outofdate) {
		deps = parse_deps(srcs.ha...)?;
		io::trunc(depsfile, 0)?;
		let out = bufio::init(depsfile, [], buf.buf);
		for (let dep .. deps) {
			unparse::ident(&out, dep)?;
			fmt::fprintln(&out)?;
		};
	} else {
		let in = bufio::newscanner_static(depsfile, buf.buf);
		for (let s => bufio::scan_line(&in)?) {
			append(deps, parse::identstr(s)?);
		};
	};
	return deps;
};

// Gather a [[module]] and all its dependencies, appending them to an existing
// slice, deduplicated, in reverse topological order, returning the index of the
// input module within the slice. Dependencies will also be written to the
// cache.
export fn gather(
	ctx: *context,
	out: *[]module,
	mod: location,
) (size | error) = {
	let stack: []str = [];
	defer free(stack);
	return _gather(ctx, out, &stack, mod)?;
};

fn _gather(
	ctx: *context,
	out: *[]module,
	stack: *[]str,
	mod: location,
) (size | error) = {
	let (modpath, srcs) = match (find(ctx, mod)) {
	case let r: (str, srcset) =>
		yield r;
	case let e: error =>
		if (len(stack) == 0) {
			return e;
		};
		return attach(strings::dup(stack[len(stack) - 1]), e);
	};
	modpath = strings::dup(modpath);
	defer free(modpath);

	for (let j = 0z; j < len(stack); j += 1) {
		if (modpath == stack[j]) {
			append(stack, modpath);
			return strings::dupall(stack[j..]): dep_cycle;
		};
	};
	for (let j = 0z; j < len(out); j += 1) {
		if (modpath == out[j].path) {
			return j;
		};
	};
	append(stack, modpath);
	defer delete(stack[len(stack) - 1]);

	let cache = get_cache(ctx.harecache, modpath)?;
	let depids = get_deps(cache, &srcs)?;
	defer free(depids);
	let deps: [](size, ast::ident) = alloc([], len(depids));
	for (let i = 0z; i < len(depids); i += 1) {
		static append(deps,
			(_gather(ctx, out, stack, depids[i])?, depids[i])
		);
	};

	append(out, module {
		name = match (mod) {
		case let mod: *path::buffer =>
			yield strings::dup(path::string(mod));
		case let mod: ast::ident =>
			yield unparse::identstr(mod);
		},
		ns = match (mod) {
		case let mod: *path::buffer =>
			yield [];
		case let mod: ast::ident =>
			yield ast::ident_dup(mod);
		},
		path = strings::dup(modpath),
		srcs = srcs,
		deps = deps,
	});
	return len(out) - 1;
};

// Free the resources associated with a [[module]].
export fn finish(mod: *module) void = {
	free(mod.name);
	ast::ident_free(mod.ns);
	free(mod.path);
	finish_srcset(&mod.srcs);
	for (let (_, ident) .. mod.deps) {
		ast::ident_free(ident);
	};
	free(mod.deps);
};

// Free all the [[module]]s in a slice of modules, and then the slice itself.
export fn free_slice(mods: []module) void = {
	for (let mod &.. mods) {
		finish(mod);
	};
	free(mods);
};
