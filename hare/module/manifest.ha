use fmt;
use fs;
use io;
use path;
use time;

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

	for (let i = 0z; i < len(manifest.inputs); i += 1) {
		void; // TODO: Write manifest
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
