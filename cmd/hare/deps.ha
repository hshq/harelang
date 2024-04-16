// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use getopt;
use hare::ast;
use hare::module;
use hare::parse;
use os;
use path;
use sort;
use sort::cmp;

type deps_fmt = enum {
	DOT,
	TERM,
};

type link = struct {
	depth: uint,
	child: size,
	final: bool,
};

fn deps(name: str, cmd: *getopt::command) (void | error) = {
	let tags = default_tags();
	defer free(tags);

	let build_dir: str = "";
	let goal = deps_fmt::TERM;

	for (let opt .. cmd.opts) {
		switch (opt.0) {
		case 'd' =>
			goal = deps_fmt::DOT;
		case 'T' =>
			merge_tags(&tags, opt.1)?;
		case =>
			abort();
		};
	};

	if (len(cmd.args) > 1) {
		getopt::printusage(os::stderr, name, cmd.help)!;
		os::exit(os::status::FAILURE);
	};

	const input = if (len(cmd.args) == 0) os::getcwd() else cmd.args[0];

	let ctx = module::context {
		harepath = harepath(),
		harecache = harecache(),
		tags = tags,
	};
	let mods: []module::module = [];

	let mod = match (parse::identstr(input)) {
	case let id: ast::ident =>
		yield id;
	case parse::error =>
		static let buf = path::buffer { ... };
		path::set(&buf, os::realpath(input)?)?;
		yield &buf;
	};
	module::gather(&ctx, &mods, mod)?;
	defer module::free_slice(mods);

	switch (goal) {
	case deps_fmt::TERM =>
		deps_graph(&mods);
	case deps_fmt::DOT =>
		fmt::println("strict digraph deps {")!;
		for (let mod .. mods) {
			for (let dep .. mod.deps) {
				const child = mods[dep.0];
				fmt::printfln("\t\"{}\" -> \"{}\";",
					mod.name, child.name)!;
			};
		};
		fmt::println("}")!;
	};
};

fn deps_graph(mods: *[]module::module) void = {
	if (len(mods) == 1 && len(mods[0].deps) == 0) {
		fmt::println(mods[0].name, "has no dependencies")!;
		return;
	};

	let links: []link = [];
	defer free(links);
	let depth: []uint = alloc([0...], len(mods));
	// traverse in reverse because reverse-topo-sort
	for (let i = len(mods) - 1; i < len(mods); i -= 1) {
		// reverse-sort deps so that we know the last in the list is the
		// "final" child during show_deps
		sort::sort(mods[i].deps, size((size, ast::ident)), &revsort);

		for (let j = 0z; j < len(links); j += 1) {
			if (i < links[j].child) {
				continue;
			};
			if (depth[i] <= links[j].depth) {
				depth[i] = links[j].depth + 1;
			};
		};

		// print in-between row
		for (let d = 0u; d < depth[i]; d += 1) {
			let passing = false;
			for (let j = 0z; j < len(links); j += 1) {
				if (i < links[j].child) {
					continue;
				};
				if (d == links[j].depth) {
					passing = true;
				};
			};
			fmt::print(if (passing) "│  " else "   ")!;
		};
		if (i < len(mods) - 1) {
			fmt::println()!;
		};

		// print row itself
		let on_path = false;
		for (let d = 0u; d < depth[i]; d += 1) {
			let connected = false;
			let passing = false;
			let final = false;
			for (let j = 0z; j < len(links); j += 1) {
				if (i < links[j].child) {
					continue;
				};
				if (d == links[j].depth) {
					passing = true;
					if (i == links[j].child) {
						connected = true;
						on_path = true;
						if (links[j].final) {
							final = true;
						};
					};
				};
			};
			fmt::print(
				if (final) "└──"
				else if (connected) "├──"
				else if (on_path) "───"
				else if (passing) "│  "
				else "   "
			)!;
		};
		fmt::println(mods[i].name)!;
		for (let j = 0z; j < len(mods[i].deps); j += 1) {
			append(links, link{
				depth = depth[i],
				child = mods[i].deps[j].0,
				final = len(mods[i].deps) == j + 1,
			});
		};
	};
};

// sorts in reverse
fn revsort(a: const *opaque, b: const *opaque) int = -cmp::sizes(a, b);
