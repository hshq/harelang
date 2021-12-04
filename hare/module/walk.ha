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
	case ver: version =>
		append(items, ns);
	};

	let iter = match (fs::iter(ctx.fs, path)) {
	case fs::wrongtype =>
		return; // Single file "module"
	case err: fs::error =>
		return err;
	case iter: *fs::iterator =>
		yield iter;
	};
	for (true) {
		const ent = match (fs::next(iter)) {
		case void =>
			break;
		case ent: fs::dirent =>
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
			defer free(linkpath);
			if (!path::abs(linkpath)) {
				let newpath = path::join(path, linkpath);
				free(linkpath);
				linkpath = newpath;
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
