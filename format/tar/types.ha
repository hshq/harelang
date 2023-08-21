// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use io;

// The size of each block in a tar file.
export def BLOCKSZ: size = 512;

// A file or directory in a tar file.
export type entry = struct {
	ent_reader,
	name: str,
	mode: uint,
	uid: uint,
	gid: uint,
	fsize: size,
	mtime: uint,
	checksum: uint,
	etype: entry_type,
	link: str,
	uname: str,
	gname: str,
	devmajor: u64,
	devminor: u64,
};

export type ent_reader = struct {
	vtable: io::stream,
	src: io::handle,
	orig: size,
	remain: size,
};

// A tar file entry. Note that some systems create tarballs with additional
// vendor-specific values for the entry type, so a default case is recommended
// when switching against this.
export type entry_type = enum u8 {
	FILE,
	HARDLINK,
	SYMLINK,
	CHARDEV,
	BLOCKDEV,
	DIRECTORY,
	FIFO,
};

// Returned if the source file size is not aligned on [[BLOCKSZ]].
export type truncated = !void;

// Returned if the source file does not contain a valid ustar archive.
export type invalid = !void;

// Tagged union of all possible error types.
export type error = !(truncated | invalid | io::error);

// Converts an [[error]] to a human-friendly representation.
export fn strerror(err: error) const str = {
	match (err) {
	case truncated =>
		return "Tar file is truncated";
	case invalid =>
		return "Tar file is invalid";
	case let err: io::error =>
		return io::strerror(err);
	};
};
