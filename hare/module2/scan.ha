use ascii;
use crypto::sha256;
use fs;
use hare::ast;
use hare::parse;
use hash;
use io;
use path;
use sort;
use strings;
use time;

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
	dirs: []directory,
};

export type filetype = enum {
	ASM,
	HARE,
};

export type file = struct {
	path: str,
	ftype: filetype,
	hash: [sha256::SIZE]u8,
	mtime: time::instant,
};

export type directory = struct {
	path: str,
	mtime: time::instant,
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

	let inputs: []str = [];
	defer strings::freeall(inputs);

	let buf = path::init();
	_scan(ctx, &state.mod, path, &inputs, &buf)?;
	sort::sort(inputs, size(str), &strcmp);

	for (let i = 0z; i < len(inputs); i += 1) {
		const file = scanfile(ctx, &state, inputs[i])?;
		append(state.mod.inputs, file);
	};

	hash::finish(&state.abi, state.mod.abi);
	return state.mod;
};

fn _scan(
	ctx: *context,
	mod: *module,
	path: str,
	inputs: *[]str,
	buf: *path::buffer,
) (void | error) = {
	const st = fs::stat(ctx.fs, path)?;
	assert(st.mask & fs::stat_mask::MTIME > 0);
	append(mod.dirs, directory {
		path = strings::dup(path),
		mtime = st.mtime,
	});

	const iter = fs::iter(ctx.fs, path)?;
	for (true) {
		const ent = match (fs::next(iter)) {
		case void =>
			break;
		case let ent: fs::dirent =>
			yield ent;
		};
		if (strings::hasprefix(ent.name, ".")) {
			continue;
		};

		path::set(buf, path, ent.name)!;
		if (fs::isfile(ent.ftype)) {
			const path = path::string(buf);
			if (included(ctx, path, false)) {
				append(inputs, strings::dup(path));
			};
		} else if (fs::isdir(ent.ftype)) {
			const path = path::string(buf);
			if (included(ctx, path, true)) {
				const path = strings::dup(path);
				defer free(path);
				_scan(ctx, mod, path, inputs, buf)?;
			};
		} else if (fs::islink(ent.ftype)) {
			abort(); // TODO
		};
	};
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

	const st = fs::stat(ctx.fs, path)?;
	assert(st.mask & fs::stat_mask::MTIME > 0);

	let result = file {
		path = strings::dup(path),
		ftype = filetype::HARE,
		mtime = st.mtime,
		...
	};
	hash::finish(&sha, result.hash);
	return result;
};

fn scanasm(ctx: *context, mod: *module, path: str) (file | error) = {
	const input = fs::open(ctx.fs, path)?;
	defer io::close(input);
	let sha = sha256::sha256();
	io::copy(&sha, input)?;

	const st = fs::stat(ctx.fs, path)?;
	assert(st.mask & fs::stat_mask::MTIME > 0);

	let result = file {
		path = strings::dup(path),
		ftype = filetype::ASM,
		mtime = st.mtime,
		...
	};
	hash::finish(&sha, result.hash);
	return result;
};

fn included(ctx: *context, path: str, isdir: bool) bool = {
	const basename = path::basename(path);
	if (isdir) {
		if (!strings::hasprefix(basename, "+")
				&& !strings::hasprefix(basename, "-")) {
			return false;
		};
	} else if (!ismodinput(basename)) {
		return false;
	};
	// XXX: Would be nice to avoid allocating the tags here
	const tags = parse_name(basename);
	defer tags_free(tags);
	return tagcompat(ctx.tags, tags);
};

fn strcmp(a: const *void, b: const *void) int = {
	const a = a: const *str;
	const b = b: const *str;
	return ascii::strcmp(*a, *b) as int;
};
