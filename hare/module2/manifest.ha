use bufio;
use dirs;
use encoding::hex;
use errors;
use fs;
use hare::ast;
use hare::parse;
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
