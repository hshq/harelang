use crypto::sha256;
use encoding::hex;
use fmt;
use hare::unparse;
use hash;
use io;
use strings;
use time;

// Writes a cache entry for the given module built with the given version of its
// dependencies.
//
// TODO: Exported temporarily
export fn write_cacheentry(
	ctx: *context,
	out: io::handle,
	mod: *module,
	deps: []*module,
) (void | error) = {
	let key: [sha256::SIZE]u8 = [0...];
	cachekey(ctx, &key, mod, deps);

	const target = gettarget(mod);

	fmt::fprint(out, "module ")?;
	hex::encode(out, key)?;
	fmt::fprintfln(out, " {}", switch (target) {
	case target::ARCHIVE =>
		yield "archive";
	case target::OBJECT =>
		yield "object";
	})?;

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

	for (let i = 0z; i < len(deps); i += 1) {
		const dep = &deps[i];
		fmt::fprintf(out, "\tdependency ")?;
		unparse::ident(out, dep.ident)?;
		fmt::fprintf(out, " ")?;
		hex::encode(out, dep.abi)?;
		fmt::fprintln(out)?;
	};
};

fn cachekey(
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

	for (let i = 0z; i < len(deps); i += 1) {
		hash::write(&key, deps[i].abi);
		hash::write(&key, [0]);
	};
	hash::write(&key, [0]);

	hash::finish(&key, out);
};

fn gettarget(mod: *module) target = {
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		if (mod.inputs[i].ftype == filetype::ASM) {
			return target::ARCHIVE;
		};
	};
	return target::OBJECT;
};
