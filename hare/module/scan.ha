use fs;
use hare::ast;
use io;
use path;
use slice;
use strings;

// Scans the files in a directory for eligible build inputs and returns a
// [version] which includes all applicable files.
export fn scan(ctx: *context, path: path::path) (version | error) = {
	let inputs: []input = [];
	let iter = match (fs::iter(ctx.fs, path)) {
		fs::wrongtype => {
			let st = fs::stat(ctx.fs, path)?;
			append(inputs, input {
				path = path,
				stat = st,
				...
			});
			return version {
				hash = "", // TODO
				inputs = inputs,
			};
		},
		err: fs::error => return err,
		iter: *fs::iterator => iter,
	};
	for (true) match (fs::next(iter)) {
		void => break,
		ent: fs::dirent => switch (ent.ftype) {
			fs::mode::DIR => void, // TODO
			fs::mode::LINK => abort(), // TODO
			fs::mode::REG => if (eligible(ctx, ent.name)) {
				let p = path::join(path, ent.name);
				let st = fs::stat(ctx.fs, p)?;
				append(inputs, input {
					path = p,
					stat = st,
					...
				});
			},
			* => void,
		},
	};
	return version {
		hash = "", // TODO
		inputs = inputs,
	};
};

// Looks up a module by its identifier from HAREPATH, and returns a [version]
// which includes all eligible build inputs.
export fn lookup(ctx: *context, name: ast::ident) (version | error) = {
	abort();
};

// TODO: Filter inputs by build tags
fn eligible(ctx: *context, name: path::path) bool = {
	if (!(name is str)) {
		return false;
	};
	let name = name as str;
	static const exts = [".ha", ".s"];
	for (let i = 0z; i < len(exts); i += 1) {
		if (strings::has_suffix(name, exts[i])) {
			return true;
		};
	};
	return false;
};
