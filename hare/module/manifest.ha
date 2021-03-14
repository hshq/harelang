use encoding::hex;
use fmt;
use fs;
use hare::ast;
use io;
use path;
use time;

// The manifest file format is a series of line-oriented records. Lines starting
// with # are ignored.
//
// - "version" indicates the manifest format version, currently 1.
// - "input" is an input file, and its fields are the file hash, path, inode,
//   and mtime as a Unix timestamp.
// - "module" is a version of a module, and includes the module hash and the set
//   of input hashes which produce it.

// Writes a module manifest to the build cache.
export fn manifest_write(ctx: *context, manifest: *manifest) (void | error) = {
	let ipath = ident_path(manifest.ident);
	defer free(ipath);
	let cachedir = path::join(ctx.cache, ipath);
	defer free(cachedir);

	let mpath = path::join(cachedir, "manifest");
	defer free(mpath);

	let l = lock(ctx.fs, cachedir)?;
	defer unlock(ctx.fs, cachedir, l);

	let fd = fs::create(ctx.fs, mpath, 0o644)?;
	defer io::close(fd);

	let ident = ast::ident_unparse_s(manifest.ident);
	defer free(ident);
	fmt::fprintfln(fd, "# {}", ident)?;
	fmt::fprintln(fd, "# This file is an internal Hare implementation detail.")?;
	fmt::fprintln(fd, "# The format is not stable.")?;
	fmt::fprintln(fd, "version 1")?;
	for (let i = 0z; i < len(manifest.inputs); i += 1) {
		const input = manifest.inputs[i];
		let hash = hex::encode(input.hash);
		defer free(hash);

		const want = fs::stat_mask::INODE | fs::stat_mask::MTIME;
		assert(input.stat.mask & want == want);
		fmt::fprintfln(fd, "input {} {} {} {}",
			hash, input.path, input.stat.inode,
			time::unix(input.stat.mtime));
	};

	for (let i = 0z; i < len(manifest.versions); i += 1) {
		const ver = manifest.versions[i];
		let hash = hex::encode(ver.hash);
		defer free(hash);

		fmt::fprintf(fd, "module {}", hash);

		for (let j = 0z; j < len(ver.inputs); j += 1) {
			let hash = hex::encode(ver.inputs[i].hash);
			defer free(hash);

			fmt::fprintf(fd, " {}", hash);
		};

		fmt::fprintln(fd);
	};
};

fn lock(fs: *fs::fs, cachedir: str) (*io::stream | error) = {
	// XXX: I wonder if this should be some generic function in fs or
	// something
	let lockpath = path::join(cachedir, "manifest.lock");
	defer free(lockpath);

	let logged = false;
	for (true) {
		match (fs::create(fs, lockpath, 0o644, fs::flags::EXCL)) {
			fd: *io::stream => return fd,
			(fs::busy | fs::exists) => void,
			err: fs::error => return err,
		};
		if (!logged) {
			fmt::errorfln("Waiting for lock on {}...", lockpath);
			logged = true;
		};
		time::sleep(1 * time::SECOND);
	};

	abort("Unreachable");
};

fn unlock(fs: *fs::fs, cachedir: str, s: *io::stream) void = {
	let lockpath = path::join(cachedir, "manifest.lock");
	defer free(lockpath);
	match (fs::remove(fs, lockpath)) {
		void => void,
		err: fs::error => abort("Error removing module lock"),
	};
};
