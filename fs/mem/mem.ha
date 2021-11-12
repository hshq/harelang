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
	fs::fs,
	data: (directory | file),
	name: str,
	hash: u64,
	next: nullable *inode,
	opencount: size,
	parent: nullable *inode,
};

type iterator = struct {
	fs::iterator,
	parent: *inode,
	curr: nullable *inode,
	idx: size,
};

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

	data = empty_dir(),
	name = "",
	hash = hash_of(""),
	next = null,
	opencount = 1,
	parent = null,
	...
});

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
	case fs::flags::RDONLY =>
		yield io::mode::READ;
	case fs::flags::WRONLY =>
		yield io::mode::WRITE;
	case fs::flags::RDWR =>
		yield io::mode::RDWR;
	case =>
		abort("invalid flag combination");
	};
	return (mode, appnd);
};

fn create(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flags...,
) (io::handle | fs::error) = {
	let t = file_flags(flags...)?;
	let mode = t.0, appnd = t.1;
	let parent = inode_find(fs: *inode, path::dirname(path))?;
	let name = path::basename(path);
	match (inode_find(parent, name)) {
	case errors::noentry => void;
	case =>
		return errors::exists;
	};
	let ino = alloc(inode {
		name = strings::dup(name),
		hash = hash_of(name),
		data = []: []u8,
		parent = parent,
		...
	});
	inode_insert(parent, ino);
	return stream_open(ino, mode, appnd)?;
};

fn open(
	fs: *fs::fs,
	path: str,
	flags: fs::flags...,
) (io::handle | fs::error) = {
	let t = file_flags(flags...)?;
	let mode = t.0, appnd = t.1;
	let ino = inode_find(fs: *inode, path)?;
	match (ino.data) {
	case directory =>
		return fs::wrongtype;
	case file =>
		return stream_open(ino, mode, appnd)?;
	};
};

fn stat(fs: *fs::fs, path: str) (fs::filestat | fs::error) = {
	match (inode_find(fs: *inode, path)?.data) {
	case directory =>
		return fs::filestat { mode = fs::mode::DIR | 0o777, ... };
	case f: file =>
		return fs::filestat {
			mode = fs::mode::REG | 0o777,
			mask = fs::stat_mask::SIZE,
			sz = len(f),
			...
		};
	};
};

fn mkdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = mksubdir(fs, path)?: *inode;
	ino.opencount = 0;
};

fn mksubdir(fs: *fs::fs, path: str) (*fs::fs | fs::error) = {
	let parent = inode_find(fs: *inode, path::dirname(path))?;
	let name = path::basename(path);
	match (inode_find(parent, name)) {
	case errors::noentry => void;
	case =>
		return errors::exists;
	};
	let ino = alloc(inode {
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

		data = empty_dir(),
		name = strings::dup(name),
		hash = hash_of(name),
		next = null,
		opencount = 1,
		parent = parent,
		...
	});
	inode_insert(parent, ino);
	return ino;
};

fn subdir(fs: *fs::fs, path: str) (*fs::fs | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	match (ino.data) {
	case directory =>
		ino.opencount += 1;
		return ino;
	case file =>
		return fs::wrongtype;
	};
};

fn iter(fs: *fs::fs, path: str) (*fs::iterator | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	match (ino.data) {
	case d: directory =>
		return alloc(iterator {
			next = &next,
			parent = ino,
			idx = 0,
			curr = d.ents[0],
		});
	case file =>
		return fs::wrongtype;
	};
};

fn next(iter: *fs::iterator) (fs::dirent | void) = {
	match (_next(iter)) {
	case null => void;
	case ino: *inode =>
		return fs::dirent {
			name = ino.name,
			ftype = match (ino.data) {
			case directory => yield fs::mode::DIR;
			case file => yield fs::mode::REG;
			},
		};
	};
};

fn _next(it: *fs::iterator) nullable *inode = {
	let iter = it: *iterator;
	if (iter.curr != null) {
		let ino = iter.curr: *inode;
		iter.curr = ino.next;
		return ino;
	};
	let p = iter.parent.data: directory;
	iter.idx += 1;
	for (iter.idx < len(p.ents)) match (p.ents[iter.idx]) {
	case null =>
		iter.idx += 1;
	case ino: *inode =>
		iter.curr = ino.next;
		return ino;
	};
	return null;
};

fn rmdir(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	if (fs: *inode == ino) {
		return errors::invalid;
	};
	match (ino.data) {
	case d: directory =>
		if (ino.opencount != 0 || d.sz != 0) {
			return errors::busy;
		};
		unlink(ino.parent: *inode, ino);
		inode_free(ino);
	case file =>
		return fs::wrongtype;
	};
};

fn remove(fs: *fs::fs, path: str) (void | fs::error) = {
	let ino = inode_find(fs: *inode, path)?;
	match (ino.data) {
	case file =>
		unlink(ino.parent: *inode, ino);
		if (ino.opencount == 0) {
			inode_free(ino);
		};
	case directory =>
		return fs::wrongtype;
	};
};

fn close(fs: *fs::fs) void = {
	let ino = fs: *inode;
	assert(ino.data is directory);
	ino.opencount -= 1;
	close_rec(ino);
};

fn close_rec(ino: *inode) void = {
	if (ino.opencount != 0 || ino.parent != null) {
		return;
	};
	let it = iterator { next = &next, parent = ino, ... };
	for (true) match (_next(&it)) {
	case null =>
		break;
	case ino: *inode =>
		ino.parent = null;
		match (ino.data) {
		case file =>
			inode_free(ino);
		case directory =>
			close_rec(ino);
		case =>
			abort("unreachable");
		};
	};
	inode_free(ino);
};
