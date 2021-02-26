use crypto::sha256;
use fs;
use hare::ast;
use hash;
use io;
use path;
use slice;
use strings;

fn hash_file(ctx: *context, path: path::path) ([]u8 | error) = {
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let f = fs::open(ctx.fs, path, io::mode::READ)?;
	io::copy(hash::writer(sha), f)?;
	return hash::finish(sha);
};

// Scans the files in a directory for eligible build inputs and returns a
// [version] which includes all applicable files.
export fn scan(ctx: *context, path: path::path) (version | error) = {
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let inputs: []input = [];
	let iter = match (fs::iter(ctx.fs, path)) {
		fs::wrongtype => {
			let st = fs::stat(ctx.fs, path)?;
			let in = input {
				path = path,
				stat = st,
				hash = hash_file(ctx, path)?,
				...
			};
			append(inputs, in);
			hash::write(sha, in.hash);
			return version {
				hash = hash::finish(sha),
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
				let in = input {
					path = p,
					stat = st,
					hash = hash_file(ctx, p)?,
					...
				};
				append(inputs, in);
				hash::write(sha, in.hash);
			},
			* => void,
		},
	};
	return version {
		hash = hash::finish(sha),
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
