use io;

// A path or path component.
export type path = (str | []u8);

// An entry was requested which does not exist.
export type noentry = void!;

// The user does not have permission to use this resource.
export type noaccess = void!;

// All possible fs error types.
export type error = (noentry | noaccess | io::error)!;

// File mode information. These bits do not necessarily reflect the underlying
// operating system's mode representation, though they were chosen to be
// consistent with typical Unix file permissions. All implementations shall
// support at least OWNER_RW, DIR, and REG.
export type mode = enum uint {
	// Read, write, and execute permissions for the file owner
	OWNER_RWX	= 0o700,
	// Read and write permissions for the file owner
	OWNER_RW	= 0o500,
	// Read permissions for the file owner
	OWNER_R		= 0o400,
	// Write permissions for the file owner
	OWNER_W		= 0o200,
	// Execute permissions for the file owner
	OWNER_X		= 0o100,

	// Read, write, and execute permissions for group members
	GROUP_RWX	= 0o070,
	// Read and write permissions for group members
	GROUP_RW	= 0o050,
	// Read permissions for group members
	GROUP_R		= 0o040,
	// Write permissions for group members
	GROUP_W		= 0o020,
	// Execute permissions for group members
	GROUP_X		= 0o010,

	// Read, write, and execute permissions for other users
	OTHER_RWX	= 0o007,
	// Read and write permissions for other users
	OTHER_RW	= 0o005,
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
};

// Information about a file or directory. The mask field defines what other
// fields are set; mode is always set.
export type filestat = struct {
	mask: stat_mask,
	mode: mode,
	uid: uint,
	gid: uint,
	sz: size,
	// TODO: atime et al
};

export type closefunc = fn(fs: *fs) void;
export type openfunc = fn(fs: *fs, path: path, mode: io::mode) (*io::stream | error);
export type createfunc = fn(fs: *fs, path: path, mode: io::mode) (*io::stream | error);
export type iterfunc = fn(fs: *fs, path: path) (*iterator | error);
export type statfunc = fn(fs: *fs, path: path) (filestat | error);
export type subdirfunc = fn(fs: *fs, path: path) (*fs | error);

// An abstract implementation of a filesystem.
export type fs = struct {
	// Frees resources associated with this filesystem.
	close: nullable *closefunc,

	// Opens a file.
	open: nullable *openfunc,

	// Creates a new file.
	create: nullable *createfunc,

	// Returns an iterator for a path, which yields the contents of a
	// directory. Pass empty string to yield from the root.
	iter: nullable *iterfunc,

	// Obtains information about a file or directory. If the target is a
	// symlink, information is returned about the link, not its target.
	stat: nullable *statfunc,

	// Opens a new filesystem for a subdirectory.
	subdir: nullable *subdirfunc,
};

// TODO
export type iterator = struct {
	placeholder: int,
};
