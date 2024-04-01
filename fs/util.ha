// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use path;
use strings;

// Converts a mode into a Unix-like mode string (e.g. "-rw-r--r--"). The string
// is statically allocated, use [[strings::dup]] to duplicate it or it will be
// overwritten on subsequent calls.
export fn mode_str(m: mode) const str = {
	static let buf: [10]u8 = [0...];
	buf = [
		(if (m & mode::DIR == mode::DIR) 'd'
			else if (m & mode::FIFO == mode::FIFO) 'p'
			else if (m & mode::SOCK == mode::SOCK) 's'
			else if (m & mode::BLK == mode::BLK) 'b'
			else if (m & mode::LINK == mode::LINK) 'l'
			else if (m & mode::CHR == mode::CHR) 'c'
			else '-'): u8,
		(if (m & mode::USER_R == mode::USER_R) 'r' else '-'): u8,
		(if (m & mode::USER_W == mode::USER_W) 'w' else '-'): u8,
		(if (m & mode::SETUID == mode::SETUID) 's'
			else if (m & mode::USER_X == mode::USER_X) 'x'
			else '-'): u8,
		(if (m & mode::GROUP_R == mode::GROUP_R) 'r' else '-'): u8,
		(if (m & mode::GROUP_W == mode::GROUP_W) 'w' else '-'): u8,
		(if (m & mode::SETGID == mode::SETGID) 's'
			else if (m & mode::GROUP_X == mode::GROUP_X) 'x'
			else '-'): u8,
		(if (m & mode::OTHER_R == mode::OTHER_R) 'r' else '-'): u8,
		(if (m & mode::OTHER_W == mode::OTHER_W) 'w' else '-'): u8,
		(if (m & mode::STICKY == mode::STICKY) 't'
			else if (m & mode::OTHER_X == mode::OTHER_X) 'x'
			else '-'): u8,
	];
	return strings::fromutf8(buf)!;
};

@test fn mode_str() void = {
	assert(mode_str(0o777: mode) == "-rwxrwxrwx");
	assert(mode_str(mode::DIR | 0o755: mode) == "drwxr-xr-x");
	assert(mode_str(0o755: mode | mode::SETUID) == "-rwsr-xr-x");
	assert(mode_str(0o644: mode) == "-rw-r--r--");
	assert(mode_str(0: mode) == "----------");
};

// Returns the permission bits of a file mode.
export fn mode_perm(m: mode) mode = (m: uint & 0o777u): mode;

// Returns the type bits of a file mode.
export fn mode_type(m: mode) mode = (m: uint & ~0o777u): mode;

// bit mask for the file type bit field
def IFMT: mode = 0o0170000u: mode;

// Returns true if this item is a regular file.
export fn isfile(mode: mode) bool = mode & IFMT == mode::REG;

// Returns true if this item is a FIFO (named pipe).
export fn isfifo(mode: mode) bool = mode & IFMT == mode::FIFO;

// Returns true if this item is a directory.
export fn isdir(mode: mode) bool = mode & IFMT == mode::DIR;

// Returns true if this item is a character device.
export fn ischdev(mode: mode) bool = mode & IFMT == mode::CHR;

// Returns true if this item is a block device.
export fn isblockdev(mode: mode) bool = mode & IFMT == mode::BLK;

// Returns true if this item is a symbolic link.
export fn islink(mode: mode) bool = mode & IFMT == mode::LINK;

// Returns true if this item is a Unix socket.
export fn issocket(mode: mode) bool = mode & IFMT == mode::SOCK;

@test fn modes() void = {
	const foo = mode::LINK | 0o755: mode;
	assert(islink(foo));
	assert(!isfile(foo));
};

// Reads all entries from a directory. The caller must free the return value
// with [[dirents_free]].
export fn readdir(fs: *fs, path: str) ([]dirent | error) = {
	let i = iter(fs, path)?;
	defer finish(i);
	let ents: []dirent = [];

	for (let d => next(i)?) {
		append(ents, dirent_dup(&d));
	};
	return ents;
};

// Frees a slice of [[dirent]]s.
export fn dirents_free(dirents: []dirent) void = {
	for (let d &.. dirents) {
		dirent_finish(d);
	};
	free(dirents);
};

// Removes a directory, and anything in it.
export fn rmdirall(fs: *fs, path: str) (void | error) = {
	let buf = path::init(path)!;
	return rmdirall_path(fs, &buf);
};

fn rmdirall_path(fs: *fs, buf: *path::buffer) (void | error) = {
	let it = iter(fs, path::string(buf))?;
	defer finish(it);
	for (let ent => next(it)?) {
		path::push(buf, ent.name)!;

		switch (ent.ftype & mode::DIR) {
		case mode::DIR =>
			rmdirall_path(fs, buf)?;
		case =>
			remove(fs, path::string(buf))?;
		};
		path::pop(buf);
	};
	return rmdir(fs, path::string(buf));
};

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components. The return value is statically
// allocated and will be overwritten on subsequent calls.
export fn realpath(fs: *fs, path: str) (str | error) = {
	static let res = path::buffer { ... };
	path::set(&res)!;
	static let pathbuf = path::buffer { ... };
	path::set(&pathbuf, resolve(fs, path))!;
	const iter = path::iter(&pathbuf);

	for (let item => path::nextiter(&iter)) {
		const item = path::push(&res, item)!;

		const link = match (readlink(fs, item)) {
		case let link: str =>
			yield link;
		case wrongtype =>
			continue;
		case let err: error =>
			return err;
		};

		if (!path::abs(link)) {
			path::push(&res, "..", link)!;
		} else {
			path::set(&res, link)!;
		};
	};

	return path::string(&res);
};
