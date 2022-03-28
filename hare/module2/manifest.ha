use bufio;
use bytes;
use dirs;
use crypto::sha256;
use encoding::hex;
use errors;
use fmt;
use fs;
use hare::ast;
use hare::parse;
use hare::unparse;
use io;
use os;
use path;
use strconv;
use strings;
use time;

// Loads a module manifest from the cache, returning a list of module versions
// available from the cache. Returns an empty list if no suitable cached
// versions are available; see [[scan]] to load from disk instead.
//
// The caller must free the return value via [[modules_finish]].
export fn load(ctx: *context, ident: ast::ident) ([]module | error) = {
	const cache = dirs::cache("hare2");
	let buf = path::init();
	path::set(&buf, cache)!;
	identpath(&buf, ident)!;
	path::add(&buf, "manifest")!;

	const in = match (fs::open(ctx.fs, path::string(&buf))) {
	case let h: io::handle =>
		yield h;
	case =>
		return [];
	};
	defer io::close(in);

	// XXX: Reduce unnecessary allocations
	// https://todo.sr.ht/~sircmpwn/hare/562
	let rbuf: [os::BUFSIZ]u8 = [0...];
	let in = bufio::buffered(in, rbuf, []);

	const line = match (bufio::scanline(&in)?) {
	case io::EOF =>
		fs::remove(ctx.fs, path::string(&buf))?;
		return [];
	case let buf: []u8 =>
		yield strings::fromutf8(buf);
	};
	defer free(line);
	if (line != "version 2") {
		fs::remove(ctx.fs, path::string(&buf))?;
		return [];
	};

	let first = true;
	let mods: []module = [];
	let mod = module { ... };
	for (true) {
		const line = match (bufio::scanline(&in)?) {
		case io::EOF =>
			break;
		case let buf: []u8 =>
			yield strings::fromutf8(buf);
		};
		defer free(line);

		const trim = strings::cut(strings::trim(line), " ");
		const cmd = trim.0, args = trim.1;

		switch (cmd) {
		case "module" =>
			if (!first) {
				append(mods, mod);
			};
			first = false;

			// XXX: https://todo.sr.ht/~sircmpwn/hare/596
			mod = module { ... };
			const cachekey = hex::decode(args)!;
			defer free(cachekey);
			mod.cachekey[..] = cachekey[..];
		case "base" =>
			mod.base = strings::dup(args);
		case "tags" =>
			yield; // TODO
		case "abi" =>
			// XXX: https://todo.sr.ht/~sircmpwn/hare/596
			const abi = hex::decode(args)!;
			defer free(abi);
			mod.abi[..] = abi[..];
		case "directory" =>
			const args = strings::cut(args, " ");
			const mtime = time::from_unix(strconv::stoi64(args.0)!);
			const path = args.1;
			append(mod.dirs, directory {
				path = strings::dup(path),
				mtime = mtime,
			});
		case "file" =>
			const args = strings::splitn(args, " ", 3);
			defer free(args);

			// XXX: https://todo.sr.ht/~sircmpwn/hare/596
			const hash = hex::decode(args[0])!;
			defer free(hash);
			const mtime = time::from_unix(strconv::stoi64(args[1])!);
			const path = strings::dup(args[2]);

			const ftype = if (isharesrc(path)) filetype::HARE
					else if (isasmsrc(path)) filetype::ASM
					else abort("Invalid input file");

			let input = file {
				path = path,
				mtime = mtime,
				ftype = ftype,
				...
			};
			input.hash[..] = hash[..];
			append(mod.inputs, input);
		case "dependency" =>
			const args = strings::cut(args, " ");

			// XXX: https://todo.sr.ht/~sircmpwn/hare/596
			const ident = parse::identstr(args.0)!;
			const abi = hex::decode(args.1)!;
			defer free(abi);

			let dep = dependency { ident = ident, ... };
			dep.abi[..] = abi[..];
			append(mod.depends, dep);
		case => abort("Invalid cache manifest");
		};
	};
	append(mods, mod);

	return mods;
};

// Frees a list of modules.
export fn modules_finish(mods: []module) void = {
	for (let i = 0z; i < len(mods); i += 1) {
		module_finish(&mods[i]);
	};
	free(mods);
};

// Writes a set of modules to the cache.
export fn store(ctx: *context, mods: []module) (void | error) = {
	assert(len(mods) > 0, "Cannot store zero mods");
	const ident = mods[0].ident;

	const cache = dirs::cache("hare2");
	let buf = path::init();
	path::set(&buf, cache)!;
	identpath(&buf, ident)!;
	fs::mkdirs(ctx.fs, path::string(&buf))?;
	path::add(&buf, ".manifest")!;

	let mpath = "";
	defer free(mpath);

	let out: io::handle = io::empty;
	let waiting = false;
	const flags = fs::flags::WRONLY | fs::flags::EXCL;
	for (let i = 0z; true; i += 1) {
		static let sbuf: [32]u8 = [0...];
		path::add(&buf, "..", fmt::bsprintf(sbuf, ".manifest.{}", i))!;

		match (fs::create(ctx.fs, path::string(&buf), 0o644, flags)) {
		case let h: io::handle =>
			mpath = strings::dup(path::string(&buf));
			out = h;
			break;
		case errors::busy =>
			continue;
		case let err: fs::error =>
			return err;
		};
	};
	defer io::close(out);

	let wbuf: [os::BUFSIZ]u8 = [0...];
	let out = bufio::buffered(out, [], wbuf);
	for (let i = 0z; i < len(mods); i += 1) {
		storemod(ctx, &out, &mods[i])?;
	};

	path::set(&buf, cache)!;
	identpath(&buf, ident)!;
	path::add(&buf, "manifest")!;

	fs::rename(ctx.fs, mpath, path::string(&buf))?;
};

fn storemod(
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
