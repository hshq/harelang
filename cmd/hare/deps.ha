use fmt;
use hare::module;
use hare::parse;
use io;
use os;
use sort;
use strings;

type depnode = struct {
	ident: str,
	depends: []size,
	depth: uint,
};

// the start of the cycle in the stack
type dep_cycle = !size;

// depth-first initial exploration, cycle-detection, reverse topological sort
fn explore_deps(ctx: *module::context, stack: *[]str, visited: *[]depnode, ident: str) (size | dep_cycle) = {
	// check for cycles
	for (let i = 0z; i < len(stack); i += 1) {
		if (ident == stack[i]) {
			append(stack, ident);
			return i: dep_cycle;
		};
	};

	// return existing depnode if visited already
	for (let i = 0z; i < len(visited); i += 1) {
		if (ident == visited[i].ident) return i;
	};
	append(stack, ident);

	let this = depnode{ident = strings::dup(ident), depends = [], depth = 0};
	let ver = match (module::lookup(ctx, parse::identstr(ident)!)) {
	case let e: module::error =>
		fmt::fatal(module::strerror(e));
	case let ver: module::version =>
		yield ver;
	};
	for (let i = 0z; i < len(ver.depends); i += 1) {
		const name = strings::join("::", ver.depends[i]...);
		defer free(name);
		const child = explore_deps(ctx, stack, visited, name)?;
		append(this.depends, child);
	};
	// reverse-sort depends so that we know the last in the list is the
	// "final" child during show_deps
	sort::sort(this.depends, size(size), &cmpsz);

	static delete(stack[len(stack)-1]);
	append(visited, this);
	return len(visited) - 1;
};

// sorts in reverse
fn cmpsz(a: const *void, b: const *void) int = (*(b: *size) - *(a: *size)): int;

type link = struct {
	depth: uint,
	child: size,
	final: bool,
};

fn show_deps(depnodes: *[]depnode) void = {
	let links: []link = [];
	defer free(links);
	// traverse in reverse because reverse-topo-sort
	for (let i = len(depnodes) - 1; 0 <= i && i < len(depnodes); i -= 1) {
		for (let j = 0z; j < len(links); j += 1) {
			if (i < links[j].child) continue;
			if (depnodes[i].depth < links[j].depth + 1) depnodes[i].depth = links[j].depth + 1;
		};

		// print in-between row
		for (let d = 0u; d < depnodes[i].depth; d += 1) {
			let passing = false;
			for (let j = 0z; j < len(links); j += 1) {
				if (i < links[j].child) continue;
				if (d == links[j].depth) {
					passing = true;
				};
			};
			fmt::print(if (passing) "│  " else "   ")!;
		};
		if (i < len(depnodes) - 1) fmt::println()!;

		// print row itself
		let on_path = false;
		for (let d = 0u; d < depnodes[i].depth; d += 1) {
			let connected = false;
			let passing = false;
			let final = false;
			for (let j = 0z; j < len(links); j += 1) {
				if (i < links[j].child) continue;
				if (d == links[j].depth) {
					passing = true;
					if (i == links[j].child) {
						connected = true;
						on_path = true;
						if (links[j].final) final = true;
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
		fmt::println(depnodes[i].ident)!;
		for (let j = 0z; j < len(depnodes[i].depends); j += 1) {
			append(links, link{
				depth = depnodes[i].depth,
				child = depnodes[i].depends[j],
				final = len(depnodes[i].depends) == j + 1,
			});
		};
	};
};
