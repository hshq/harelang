// TODO:
// - Symlinks, hard links
// - More fs::flags
// - fs::stat_mask::INODE, ::*TIME

use errors;
use fs;
use io;
use path;
use strings;

type directory = struct {
	ents: []nullable *inode,
	sz: size,
};

type file = []u8;

type inode = struct {
	fs: fs::fs,
	data: (directory | file),
	name: str,
	hash: u64,
	next: nullable *inode,
	opencount: size,
	parent: nullable *inode,
};

type iterator = struct {
	it: fs::iterator,
	parent: *inode,
	curr: nullable *inode,
	idx: size,
};

const inode_iface: fs::fs = fs::fs {
	close = &close,
	create = &create,
	iter = &iter,
	mkdir = &mkdir,
	mksubdir = &mksubdir,
	open = &open,
	remove = &remove,
	rmdir = &rmdir,
	stat = &stat,
	subdir = &subdir,
	...
};

const fs_iter: fs::iterator = fs::iterator { next = &next, };

const supported_flags: fs::flags = (
	fs::flags::RDONLY |
	fs::flags::WRONLY |
	fs::flags::RDWR   |
	fs::flags::APPEND);

// Returns the root of an new in-memory file system. The entire directory
// structure and files with metadata only exist in volatile memory. Arbitrary
// number of handles to the same directory simultaneously are allowed. Supports
// any number of readers or one writer at the same time on a file.
export fn memopen() *fs::fs = alloc(inode {
	fs = inode_iface,
	data = empty_dir(),
	name = "",
	opencount = 1,
	parent = null,
}): *fs::fs;

fn file_flags(flags: fs::flags...) ((io::mode, bool) | fs::error) = {
	let fl: fs::flags = 0;
	for (let i = 0z; i < len(flags); i += 1) {
		if (flags[i] & supported_flags != flags[i]) {
			return errors::unsupported;
		};
		fl |= flags[i];
	};
	let appnd = fl & fs::flags::APPEND == fs::flags::APPEND;
	let mode = switch (fl & (~fs::flags::APPEND)) {
		fs::flags::RDONLY => io::mode::READ,
		fs::flags::WRONLY => io::mode::WRITE,
		fs::flags::RDWR   => io::mode::RDWR,
		* => abort("invalid flag combination"),
	};
	return (mode, appnd);
};

fn create(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flags...,
) (*io::stream | fs::error) = {
	let t = file_flags(flags...)?;
	let mode = t.0, appnd = t.1;

	let parent = fs: *inode;
	match (inode_find(parent, path)) {
		errors::noentry => void,
		* => return errors::exists,
	};
	if (path::dirname(path) != path) {
		parent = inode_find(parent, path::dirname(path))?;
	};

	let name = strings::dup(path::basename(path));
	let ino = alloc(inode {
		name = name,
		hash = hash_of(name),
		data = []: []u8,
		parent = parent,
	});
	inode_insert(parent, ino);
	return stream_open(ino, mode, appnd);
};

fn open(
	fs: *fs::fs,
	path: str,
	flags: fs::flags...,
) (*io::stream | fs::error) = {
	let t = file_flags(flags...)?;
	let mode = t.0, appnd = t.1;
	let ino = inode_find(fs: *inode, path)?;
	if (ino.data is directory) {
		return fs::wrongtype;
	};
	return stream_open(ino, mode, appnd);
};

fn stat(fs: *fs::fs, path: str) (fs::filestat | fs::error) = {
	return match(inode_find(fs: *inode, path)?.data) {
		directory => fs::filestat { mode = fs::mode::DIR | 0o777, ... },
		f: file => fs::filestat {
			mode = fs::mode::REG | 0o777,
			mask = fs::stat_mask::SIZE,
			sz = len(f),
		},
	};
};

fn mkdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = mksubdir(fs, path)?: *inode;
	ino.opencount = 0;
	return void;
};

fn mksubdir(fs: *fs::fs, path: str) (*fs::fs | fs::error) = {
	let parent = fs: *inode;
	match (inode_find(parent, path)) {
		errors::noentry => void,
		* => return errors::exists,
	};
	if (path::dirname(path) != path) {
		parent = inode_find(parent, path::dirname(path))?;
	};
	let name = strings::dup(path::basename(path));
	let ino = alloc(inode {
		fs = inode_iface,
		data = empty_dir(),
		name = name,
		hash = hash_of(name),
		opencount = 1,
		parent = parent,
	});
	inode_insert(parent, ino);
	return ino: *fs::fs;
};

fn subdir(fs: *fs::fs, path: str) (*fs::fs | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	if (!(ino.data is directory)) {
		return fs::wrongtype;
	};
	ino.opencount += 1;
	return ino: *fs::fs;
};

fn iter(fs: *fs::fs, path: str) (*fs::iterator | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	if (!(ino.data is directory)) {
		return fs::wrongtype;
	};
	let p = ino.data: directory;
	return alloc(iterator {
		it = fs::iterator { next = &next, },
		parent = ino,
		idx = 0,
		curr = p.ents[0],
	}): *fs::iterator;
};

fn next(iter: *fs::iterator) (fs::dirent | void) = match (_next(iter)) {
	null => void,
	ino: *inode => fs::dirent {
		name = ino.name,
		ftype = match (ino.data) {
			directory => fs::mode::DIR,
			file      => fs::mode::REG,
		},
	},
};

fn _next(it: *fs::iterator) nullable *inode = {
	let iter = it: *iterator;
	if (iter.curr != null) {
		let ino = iter.curr: *inode;
		iter.curr = ino.next;
		return ino;
	};
	let p = iter.parent.data as directory;
	iter.idx += 1;
	for (iter.idx < len(p.ents)) match (p.ents[iter.idx]) {
		null => iter.idx += 1,
		ino: *inode => {
			iter.curr = ino.next;
			return ino;
		},
	};
	return null;
};

fn rmdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	if (fs: *inode == ino) {
		return errors::invalid;
	};
	if (!(ino.data is directory)) {
		return fs::wrongtype;
	};
	let p = ino.data as directory;
	if (ino.opencount != 0 || p.sz != 0) {
		return errors::busy;
	};
	unlink(ino.parent: *inode, ino);
	inode_free(ino);
};

fn remove(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	if (!(ino.data is file)) {
		return fs::wrongtype;
	};
	unlink(ino.parent: *inode, ino);
	if (ino.opencount == 0) {
		inode_free(ino);
	};
};

fn close(fs: *fs::fs) void = {
	let ino = fs: *inode;
	if (!(ino.data is directory)) {
		return fs::wrongtype;
	};
	ino.opencount -= 1;
	close_rec(ino);
};

fn close_rec(ino: *inode) void = {
	if (ino.opencount != 0 || ino.parent != null) {
		return;
	};
	let it = iterator { it = fs_iter, parent = ino, ... };
	for (true) match (_next(&it: *fs::iterator)) {
		null => break,
		ino: *inode => {
			ino.parent = null;
			match (ino.data) {
				file => inode_free(ino),
				directory => close_rec(ino),
				* => abort("unreachable"),
			};
		},
	};
	inode_free(ino);
};
