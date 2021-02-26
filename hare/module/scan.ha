use crypto::sha256;
use fs;
use hare::ast;
use hare::lex;
use hare::parse;
use hash;
use io;
use path;
use slice;
use strings;

// Scans the files in a directory for eligible build inputs and returns a
// [version] which includes all applicable files and their dependencies.
export fn scan(ctx: *context, path: path::path) (version | error) = {
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let inputs: []input = [];
	let deps: []ast::ident = [];
	let iter = match (fs::iter(ctx.fs, path)) {
		fs::wrongtype => {
			let st = fs::stat(ctx.fs, path)?;
			let in = input {
				path = path,
				stat = st,
				hash = scan_file(ctx, path, &deps)?,
				...
			};
			append(inputs, in);
			hash::write(sha, in.hash);
			return version {
				hash = hash::finish(sha),
				depends = deps,
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
					hash = scan_file(ctx, p, &deps)?,
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
		depends = deps,
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

fn scan_file(
	ctx: *context,
	path: path::path,
	deps: *[]ast::ident,
) ([]u8 | error) = {
	let f = fs::open(ctx.fs, path, io::mode::READ)?;
	let sha = sha256::sha256();
	//defer! hash::close(sha);
	let tee = io::tee(f, hash::writer(sha));
	defer io::close(tee);

	let lexer = lex::init(tee, path as str);
	let imports = parse::imports(&lexer)?;
	for (let i = 0z; i < len(imports); i += 1) {
		let ident = match (imports[i]) {
			m: ast::import_module => m: ast::ident,
			a: ast::import_alias => a.ident,
			o: ast::import_objects => o.ident,
		};
		if (!have_ident(deps, ident)) {
			append(*deps, ident);
		};
	};

	io::copy(io::empty, tee)?; // Finish spooling out the file for the SHA
	return hash::finish(sha);
};

fn have_ident(sl: *[]ast::ident, id: ast::ident) bool = {
	// XXX: We shouldn't have to deref sl here
	for (let i = 0z; i < len(*sl); i += 1) {
		if (ast::ident_eq(sl[i], id)) {
			return true;
		};
	};
	return false;
};
