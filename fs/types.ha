use io;
use strings;
use path;

// An entry was requested which does not exist.
export type noentry = void!;

// An attempt was made to create a file or directory which already exists.
export type exists = void!;

// The user does not have permission to use this resource.
export type noaccess = void!;

// An entry of a particular type was sought, but is something else in practice.
// For example, opening a file with [iter].
export type wrongtype = void!;

// All possible fs error types.
export type error = (noentry | noaccess | exists | wrongtype | io::error)!;

// File mode information. These bits do not necessarily reflect the underlying
// operating system's mode representation, though they were chosen to be
// consistent with typical Unix file permissions. All implementations shall
// support at least USER_RW, DIR, and REG.
export type mode = enum uint {
	// Read, write, and execute permissions for the file owner
	USER_RWX	= 0o700,
	// Read and write permissions for the file owner
	USER_RW		= 0o600,
	// Read and execute permissions for the file owner
	USER_RX		= 0o500,
	// Read permissions for the file owner
	USER_R		= 0o400,
	// Write permissions for the file owner
	USER_W		= 0o200,
	// Execute permissions for the file owner
	USER_X		= 0o100,

	// Read, write, and execute permissions for group members
	GROUP_RWX	= 0o070,
	// Read and write permissions for group members
	GROUP_RW	= 0o060,
	// Read and execute permissions for group members
	GROUP_RX	= 0o050,
	// Read permissions for group members
	GROUP_R		= 0o040,
	// Write permissions for group members
	GROUP_W		= 0o020,
	// Execute permissions for group members
	GROUP_X		= 0o010,

	// Read, write, and execute permissions for other users
	OTHER_RWX	= 0o007,
	// Read and write permissions for other users
	OTHER_RW	= 0o006,
	// Read and execute permissions for other users
	OTHER_RX	= 0o005,
	// Read permissions for other users
	OTHER_R		= 0o004,
	// Write permissions for other users
	OTHER_W		= 0o002,
	// Execute permissions for other users
	OTHER_X		= 0o001,

	// Entry has the set-uid bit set
	SETUID	= 0o4000,
	// Entry has the set-gid bit set
	SETGID	= 0o2000,
	// Entry has the sticky bit set
	STICKY	= 0o1000,

	// Entry is of an unknown type
	UNKNOWN	= 0,
	// Entry is a FIFO (named pipe)
	FIFO	= 0o010000,
	// Entry is a directory
	DIR	= 0o040000,
	// Entry is a character device
	CHR	= 0o020000,
	// Entry is a block device
	BLK	= 0o060000,
	// Entry is a regular file
	REG	= 0o100000,
	// Entry is a symbolic link
	LINK	= 0o120000,
	// Entry is a Unix socket
	SOCK	= 0o140000,
};

// A mask defining what items are populated in the stat structure.
export type stat_mask = enum uint {
	UID	= 1 << 0,
	GID	= 1 << 1,
	SIZE	= 1 << 2,
	INODE	= 1 << 3,
};

// Information about a file or directory. The mask field defines what other
// fields are set; mode and path are always set.
export type filestat = struct {
	mask: stat_mask,
	mode: mode,
	uid: uint,
	gid: uint,
	sz: size,
	inode: u64,
	// TODO: atime et al
};

// An entry in a directory. This may be borrowed from the filesystem's internal
// state; if you want to keep this around beyond one call to [next], use
// [dirent_dup].
export type dirent = struct {
	// The name of this entry. Not fully qualified: for example,
	// "foo/bar/baz.txt" would store "baz.txt" here.
	name: path::path,

	// The type of this entry. The permission bits may be unset.
	ftype: mode,
};

// Duplicates a [dirent] object. Call [dirent_free] to get rid of it later.
export fn dirent_dup(e: dirent) dirent = {
	let new = e;
	new.name = match (new.name) {
		s: str => strings::dup(s),
		b: []u8 => {
			let n: []u8 = [];
			append(n, ...b);
			n;
		},
	};
	return new;
};

// Frees a [dirent] object which was duplicated with [dirent_dup].
export fn dirent_free(e: dirent) void = match (e.name) {
	s: str => free(s),
	b: []u8 => free(b),
};

export type closefunc = fn(fs: *fs) void;
export type openfunc = fn(fs: *fs, path: path::path, mode: io::mode) (*io::stream | error);
export type createfunc = fn(fs: *fs, path: path::path, mode: io::mode) (*io::stream | error);
export type iterfunc = fn(fs: *fs, path: path::path) (*iterator | error);
export type statfunc = fn(fs: *fs, path: path::path) (filestat | error);
export type subdirfunc = fn(fs: *fs, path: path::path) (*fs | error);
export type mkdirfunc = fn(fs: *fs, path: path::path) (void | error);
export type mksubdirfunc = fn(fs: *fs, path: path::path) (*fs | error);

// An abstract implementation of a filesystem. To create a custom stream, embed
// this type as the first member of a struct with user-specific data and fill
// out these fields as appropriate.
export type fs = struct {
	// Frees resources associated with this filesystem.
	close: nullable *closefunc,

	// Opens a file.
	open: nullable *openfunc,

	// Creates a new file.
	create: nullable *createfunc,

	// Returns an iterator for a path, which yields the contents of a
	// directory. Pass empty string to yield from the root.
	//
	// The iterator must return all entries without error. If an error would
	// occur, it should be identified here and returned upfront.
	iter: nullable *iterfunc,

	// Obtains information about a file or directory. If the target is a
	// symlink, information is returned about the link, not its target.
	stat: nullable *statfunc,

	// Opens a new filesystem for a subdirectory.
	subdir: nullable *subdirfunc,

	// Creates a directory.
	mkdir: nullable *mkdirfunc,

	// Creates a directory and returns a subdir for it.
	mksubdir: nullable *mksubdirfunc,
};

export type nextfunc = fn(iter: *iterator) (dirent | void);

export type iterator = struct {
	// Returns the next member of the directory, or void if there are none
	// remaining.
	next: *nextfunc,
};
