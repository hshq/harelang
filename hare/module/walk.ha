// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use fs;
use hare::ast;
use path;
use strings;

// Recursively scans the filesystem to find valid Hare modules for the given
// [[context]], given the path to the entry point. The caller must free the
// return value with [[walk_free]].
export fn walk(ctx: *context, path: str) ([]ast::ident | error) = {
	let items: []ast::ident = [];
	_walk(ctx, path, &items, [])?;
	return items;
};

fn _walk(
	ctx: *context,
	path: str,
	items: *[]ast::ident,
	ns: ast::ident,
) (void | error) = {
	match (scan(ctx, path)) {
	case error =>
		void;
	case let ver: version =>
		append(items, ns);
	};

	let iter = match (fs::iter(ctx.fs, path)) {
	case fs::wrongtype =>
		return; // Single file "module"
	case let err: fs::error =>
		return err;
	case let iter: *fs::iterator =>
		yield iter;
	};
	defer fs::finish(iter);

	// TODO: Refactor me to use path::buffer
	for (true) {
		const ent = match (fs::next(iter)) {
		case void =>
			break;
		case let ent: fs::dirent =>
			yield ent;
		};

		if (strings::hasprefix(ent.name, "+")
				|| strings::hasprefix(ent.name, "-")
				|| strings::hasprefix(ent.name, ".")) {
			continue;
		};

		switch (ent.ftype) {
		case fs::mode::DIR =>
			// TODO: Test that this is a valid name (grammar)
			let subpath = path::join(path, ent.name);
			defer free(subpath);
			let newns = ast::ident_dup(ns);
			append(newns, strings::dup(ent.name));
			_walk(ctx, subpath, items, newns)?;
		case fs::mode::LINK =>
			let linkpath = path::join(path, ent.name);
			defer free(linkpath);
			let linkpath = fs::readlink(ctx.fs, linkpath)?;
			if (!path::abs(linkpath)) {
				linkpath = path::join(path, linkpath);
			};

			const st = fs::stat(ctx.fs, linkpath)?;
			if (fs::isdir(st.mode)) {
				let subpath = path::join(path, ent.name);
				defer free(subpath);
				let newns = ast::ident_dup(ns);
				append(newns, strings::dup(ent.name));
				_walk(ctx, subpath, items, newns)?;
			};
		case fs::mode::REG =>
			void; // no-op
		case => abort();
		};
	};
};

// Frees resources associated with the return value of [[walk]].
export fn walk_free(items: []ast::ident) void = {
	for (let i = 0z; i < len(items); i += 1) {
		ast::ident_free(items[i]);
	};
	free(items);
};
