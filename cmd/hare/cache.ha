// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use fs;
use getopt;
use os;
use path;

// TODO: flesh this out some more. we probably want to have some sort of
// per-module statistics (how much space it's taking up in the cache and whether
// it's up to date for each tagset) and maybe also some sort of auto-pruner
// (only prune things that can no longer ever be considered up-to-date?) so that
// people don't need to periodically run hare cache -c n order to avoid the
// cache growing indefinitely

fn cache(name: str, cmd: *getopt::command) (void | error) = {
	let clear = false;
	for (let opt .. cmd.opts) {
		switch (opt.0) {
		case 'c' =>
			clear = true;
		case => abort();
		};
	};
	if (len(cmd.args) != 0) {
		getopt::printusage(os::stderr, name, cmd.help)?;
		os::exit(os::status::FAILURE);
	};
	let cachedir = harecache();

	if (clear) {
		os::rmdirall(cachedir)?;
		fmt::println(cachedir, "(0 B)")?;
		return;
	};

	os::mkdirs(cachedir, 0o755)!;
	let buf = path::init(cachedir)?;
	let sz = dirsize(&buf)?;
	const suffix = ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"];
	let i = 0z;
	for (i < len(suffix) - 1 && sz >= 1024; i += 1) {
		sz /= 1024;
	};
	fmt::printfln("{} ({} {})", cachedir, sz, suffix[i])?;
};

fn dirsize(buf: *path::buffer) (size | error) = {
	let s = 0z;
	let it = os::iter(path::string(buf))?;
	defer fs::finish(it);

	for (let d => fs::next(it)?) {
		path::push(buf, d.name)?;
		let stat = os::stat(path::string(buf))?;
		s += stat.sz;
		if (fs::isdir(stat.mode)) {
			s += dirsize(buf)?;
		};
		path::pop(buf);
	};
	return s;
};
