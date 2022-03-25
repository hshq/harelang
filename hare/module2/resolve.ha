use fs;
use hare::ast;
use os;
use path;
use strings;

// Resolves the directory in which the given module resides for the provided
// context. The caller must free the return value.
export fn resolve(ctx: *context, ident: ast::ident) (str | error) = {
	let buf = path::init();
	for (let i = 0z; i < len(ctx.paths); i += 1) {
		path::set(&buf, ctx.paths[i])!;
		identpath(&buf, ident)!;
		if (ismodule(ctx, path::string(&buf))) {
			return strings::dup(path::string(&buf));
		};
	};
	return modnotfound;
};

// Returns true if the given directory contains a valid Hare module.
export fn ismodule(ctx: *context, path: str) bool = {
	const iter = match (fs::iter(ctx.fs, path)) {
	case fs::error =>
		return false;
	case let iter: *fs::iterator =>
		yield iter;
	};

	for (true) {
		const ent = match (fs::next(iter)) {
		case void =>
			break;
		case let ent: fs::dirent =>
			yield ent;
		};
		if (ent.name == "." || ent.name == "..") {
			continue;
		};

		if (fs::isfile(ent.ftype)) {
			if (ismodinput(ent.name)) {
				return true;
			};
		} else if (fs::isdir(ent.ftype)) {
			if (hastag(ent.name)) {
				let subdir = path::join(path, ent.name);
				defer free(subdir);
				if (ismodule(ctx, subdir)) {
					return true;
				};
			};
		} else if (fs::islink(ent.ftype)) {
			void; // TODO
		};
	};

	return false;
};

fn isharesrc(path: str) bool = strings::hassuffix(path, ".ha");
fn isasmsrc(path: str) bool = strings::hassuffix(path, ".s");
fn ismodinput(path: str) bool = isharesrc(path) || isasmsrc(path);
fn hastag(name: str) bool = strings::hasprefix(name, "+") || strings::hasprefix(name, "-");
