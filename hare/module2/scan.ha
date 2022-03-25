use crypto::sha256;
use fs;
use hare::ast;
use hare::parse;
use hash;
use io;
use path;
use strings;

type scan_state = struct {
	mod: module,
	abi: sha256::state,
};

export type module = struct {
	base: str,
	abi: [sha256::SIZE]u8,
	hash: [sha256::SIZE]u8,
	depends: []ast::ident,
	inputs: []file,
};

export type filetype = enum {
	ASM,
	HARE,
};

export type file = struct {
	path: str,
	ftype: filetype,
	hash: [sha256::SIZE]u8,
};

// Scans a directory containing a Hare module, returning a list of input files,
// dependencies, the ABI hash, and so on. The caller must pass the return value
// to [[module_finish]] when they are done using it.
export fn scan(ctx: *context, path: str) (module | error) = {
	let state = scan_state {
		mod = module {
			base = strings::dup(path),
			...
		},
		abi = sha256::sha256(),
	};

	// TODO: alpha-sort inputs and filter by tags
	let buf = path::init();
	const iter = fs::iter(ctx.fs, path)?;
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

		path::set(&buf, state.mod.base, ent.name)!;
		if (fs::isfile(ent.ftype)) {
			if (ismodinput(ent.name)) {
				const path = path::string(&buf);
				const file = scanfile(ctx, &state, path)?;
				append(state.mod.inputs, file);
			};
		} else if (fs::isdir(ent.ftype)) {
			abort(); // TODO
		} else if (fs::islink(ent.ftype)) {
			abort(); // TODO
		};
	};

	hash::finish(&state.abi, state.mod.abi);
	return state.mod;
};

// Note: Must be called in alphabetical order so that the ABI hash is computed
// correctly.
fn scanfile(ctx: *context, state: *scan_state, path: str) (file | error) = {
	if (isharesrc(path)) {
		return scanhare(ctx, state, path);
	} else if (isasmsrc(path)) {
		return scanasm(ctx, state, path);
	} else {
		abort("Unsupported file type for module input");
	};
};

fn scanhare(ctx: *context, state: *scan_state, path: str) (file | error) = {
	const input = fs::open(ctx.fs, path)?;
	defer io::close(input);
	let sha = sha256::sha256();
	const input = &io::tee(input, &sha);
	scanabi(state, path, input)?;

	let result = file {
		path = strings::dup(path),
		ftype = filetype::HARE,
		...
	};
	hash::finish(&sha, result.hash);
	return result;
};

fn scanasm(ctx: *context, mod: *module, path: str) (file | error) = {
	abort(); // TODO
};
