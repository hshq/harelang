// License: GPL-3.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use fmt;
use hare::ast;
use hare::module;
use io;
use strings;
use strio;

// Forked from [[hare::unparse]].
fn newline(out: io::handle, indent: size) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "\n")?;
	for (let i = 0z; i < indent; i += 1) {
		n += fmt::fprint(out, "\t")?;
	};
	return n;
};

fn multiline_comment(s: str) bool =
	strings::byteindex(s, '\n') as size != len(s) - 1;

fn trim_comment(s: str) str = {
	let trimmed = strio::dynamic();
	let tok = strings::tokenize(s, "\n");
	for (true) {
		const line = match (strings::next_token(&tok)) {
		case void =>
			break;
		case let line: str =>
			yield line;
		};
		strio::concat(&trimmed, strings::trimprefix(line, " "), "\n")!;
	};
	return strings::dup(strio::string(&trimmed));
};

fn submodules(ctx: *context) ([]str | error) = {
	let identpath = module::identpath(ctx.ident);
	defer free(identpath);

	let submodules: []str = [];
	for (let i = 0z; i < len(ctx.version.subdirs); i += 1) {
		let dir = ctx.version.subdirs[i];
		// XXX: the list of reserved directory names is not yet
		// finalized. See https://todo.sr.ht/~sircmpwn/hare/516
		if (dir == "contrib") continue;
		if (dir == "cmd") continue;
		if (dir == "docs") continue;
		if (dir == "ext") continue;
		if (dir == "vendor") continue;
		if (dir == "scripts") continue;

		let submod = [identpath, dir]: ast::ident;
		match (module::lookup(ctx.mctx, submod)) {
		case let ver: module::version =>
			// TODO: free version data
			void;
		case module::notfound =>
			continue;
		case let err: module::error =>
			return err;
		};

		append(submodules, dir);
	};

	return submodules;
};
