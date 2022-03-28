use bytes;
use crypto::sha256;
use encoding::hex;
use fmt;
use fs;
use hare::unparse;
use hash;
use io;
use strings;
use time;

// Returns true if the given module is "current" (up to date). Note that this
// function does not test for ABI compatibility with its dependencies.
export fn iscurrent(ctx: *context, mod: *module) bool = {
	// Treat errors as if the module is outdated
	match (_iscurrent(ctx, mod)) {
	case let b: bool =>
		return b;
	case error =>
		return false;
	};
};

fn _iscurrent(ctx: *context, mod: *module) (bool | error) = {
	let current = true;
	for (let i = 0z; i < len(mod.dirs); i += 1) {
		const dir = mod.dirs[i];
		const st = fs::stat(ctx.fs, dir.path)?;
		assert(st.mask & fs::stat_mask::MTIME > 0);
		if (time::compare(st.mtime, dir.mtime) != 0) {
			current = false;
			break;
		};
	};
	if (current) {
		return true;
	};

	current = true;
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		const input = &mod.inputs[i];
		const st = fs::stat(ctx.fs, input.path)?;
		assert(st.mask & fs::stat_mask::MTIME > 0);
		if (time::compare(st.mtime, input.mtime) != 0) {
			current = false;
			break;
		};
	};
	if (current) {
		return true;
	};

	current = true;
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		const input = &mod.inputs[i];
		const file = fs::open(ctx.fs, input.path)?;
		defer io::close(file);
		let sha = sha256::sha256();
		io::copy(&sha, file)?;
		let hash: [sha256::SIZE]u8 = [0...];
		hash::finish(&sha, hash);
		if (!bytes::equal(hash, input.hash)) {
			current = false;
			break;
		};
	};

	return current;
};

// Writes a cache entry for the given module built with the given version of its
// dependencies.
//
// TODO: Exported temporarily
export fn write_cacheentry(
	ctx: *context,
	out: io::handle,
	mod: *module,
) (void | error) = {
	const zeroes: [sha256::SIZE]u8 = [0...];
	assert(!bytes::equal(mod.cachekey, zeroes),
		"Attempted to write incomplete module to cache");

	fmt::fprint(out, "module ")?;
	hex::encode(out, mod.cachekey)?;
	fmt::fprintln(out)?;

	fmt::fprintfln(out, "\tbase {}", mod.base)?;

	fmt::fprintf(out, "\ttags")?;
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		fmt::fprintf(out, " {}{}", switch (ctx.tags[i].mode) {
		case tag_mode::INCLUSIVE =>
			yield '+';
		case tag_mode::EXCLUSIVE =>
			yield '-';
		}, ctx.tags[i].name)?;
	};
	fmt::fprintln(out)?;

	// TODO: Add config hash

	fmt::fprintf(out, "\tabi ")?;
	hex::encode(out, mod.abi)?;
	fmt::fprintln(out)?;

	for (let i = 0z; i < len(mod.dirs); i += 1) {
		const dir = &mod.dirs[i];
		fmt::fprintfln(out, "\tdirectory {} {}",
			time::unix(dir.mtime), dir.path)?;
	};

	for (let i = 0z; i < len(mod.inputs); i += 1) {
		const input = &mod.inputs[i];
		fmt::fprintf(out, "\tfile ")?;
		hex::encode(out, input.hash)?;
		fmt::fprintfln(out, " {} {}",
			time::unix(input.mtime), input.path)?;
	};

	for (let i = 0z; i < len(mod.depends); i += 1) {
		const dep = &mod.depends[i];
		fmt::fprintf(out, "\tdependency ")?;
		unparse::ident(out, dep.ident)?;
		fmt::fprintf(out, " ")?;
		hex::encode(out, dep.abi)?;
		fmt::fprintln(out)?;
	};
};

// XXX: Temporarily exported
export fn cachekey(
	ctx: *context,
	out: *[sha256::SIZE]u8,
	mod: *module,
	deps: []*module,
) void = {
	let key = sha256::sha256();
	for (let i = 0z; i < len(ctx.tags); i += 1) {
		const tag = &ctx.tags[i];
		if (tag.mode == tag_mode::INCLUSIVE) {
			hash::write(&key, [1]);
		} else {
			hash::write(&key, [0]);
		};
		hash::write(&key, strings::toutf8(tag.name));
		hash::write(&key, [0]);
	};
	hash::write(&key, [0]);

	// TODO: Add config hash

	for (let i = 0z; i < len(mod.inputs); i += 1) {
		hash::write(&key, mod.inputs[i].hash);
		hash::write(&key, [0]);
	};
	hash::write(&key, [0]);

	// TODO: Sort dependencies
	for (let i = 0z; i < len(deps); i += 1) {
		hash::write(&key, deps[i].abi);
		hash::write(&key, [0]);
	};
	hash::write(&key, [0]);

	hash::finish(&key, out);
};
