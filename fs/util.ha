use io;
use strio;

// Returns a human-friendly representation of an error.
export fn errstr(err: error) const str = match (err) {
	noentry => "File or directory not found",
	noaccess => "Permission denied",
	err: io::error => io::errstr(err),
};

// Converts a mode into a Unix-like mode string (e.g. "-rw-r--r--"). The string
// is statically allocated, use [strings::dup] to duplicate it or it will be
// overwritten on subsequent calls.
export fn mode_str(m: mode) const str = {
	// TODO: Rewrite me to avoid circular dependency on fmt
	abort();
	//static let buf: [11]u8 = [0...];
	//let sink = strio::fixed(buf);
	//fmt::fprintf(sink, "{}{}{}{}{}{}{}{}{}{}",
	//	if (m & mode::DIR == mode::DIR) "d"
	//		else if (m & mode::FIFO == mode::FIFO) "p"
	//		else if (m & mode::SOCK == mode::SOCK) "s"
	//		else if (m & mode::BLK == mode::BLK) "b"
	//		else if (m & mode::LINK == mode::LINK) "l"
	//		else if (m & mode::CHR == mode::CHR) "c"
	//		else "-",
	//	if (m & mode::USER_R == mode::USER_R) "r" else "-",
	//	if (m & mode::USER_W == mode::USER_W) "w" else "-",
	//	if (m & mode::SETUID == mode::SETUID) "s"
	//		else if (m & mode::USER_X == mode::USER_X) "x"
	//		else "-",
	//	if (m & mode::GROUP_R == mode::GROUP_R) "r" else "-",
	//	if (m & mode::GROUP_W == mode::GROUP_W) "w" else "-",
	//	if (m & mode::SETGID == mode::SETGID) "s"
	//		else if (m & mode::GROUP_X == mode::GROUP_X) "x"
	//		else "-",
	//	if (m & mode::OTHER_R == mode::OTHER_R) "r" else "-",
	//	if (m & mode::OTHER_W == mode::OTHER_W) "w" else "-",
	//	if (m & mode::STICKY == mode::STICKY) "t"
	//		else if (m & mode::OTHER_X == mode::OTHER_X) "x"
	//		else "-",
	//	);
	//return strio::string(sink);
};

//@test fn mode_str() void = {
//	assert(mode_str(0o777: mode) == "-rwxrwxrwx");
//	assert(mode_str(mode::DIR | 0o755: mode) == "drwxr-xr-x");
//	assert(mode_str(0o755: mode | mode::SETUID) == "-rwsr-xr-x");
//	assert(mode_str(0o644: mode) == "-rw-r--r--");
//	assert(mode_str(0: mode) == "----------");
//};

// Returns the permission bits of a file mode.
export fn mode_perm(m: mode) mode = (m: uint & 0o777u): mode;

// Returns the type bits of a file mode.
export fn mode_type(m: mode) mode = (m: uint & ~0o777u): mode;

// Returns true if this item is a regular file.
export fn is_file(mode: mode) bool = mode & mode::REG == mode::REG;

// Returns true if this item is a FIFO (named pipe).
export fn is_fifo(mode: mode) bool = mode & mode::FIFO == mode::FIFO;

// Returns true if this item is a directory.
export fn is_dir(mode: mode) bool = mode & mode::DIR == mode::DIR;

// Returns true if this item is a character device.
export fn is_chdev(mode: mode) bool = mode & mode::CHR == mode::CHR;

// Returns true if this item is a block device.
export fn is_blockdev(mode: mode) bool = mode & mode::BLK == mode::BLK;

// Returns true if this item is a symbolic link.
export fn is_link(mode: mode) bool = mode & mode::LINK == mode::LINK;

// Returns true if this item is a Unix socket.
export fn is_socket(mode: mode) bool = mode & mode::SOCK == mode::SOCK;

// Reads all entries from a directory. The caller must free the return value
// with [dirents_free].
export fn readdir(fs: *fs, path: path) ([]dirent | error) = {
	let i = iter(fs, path)?;
	let ents: []dirent = [];
	for (true) {
		match (next(i)) {
			d: dirent => append(ents, dirent_dup(d)),
			void => break,
		};
	};
	return ents;
};

// Frees a slice of [dirent]s.
export fn dirents_free(d: []dirent) void = {
	for (let i = 0z; i < len(d); i += 1) {
		dirent_free(d[i]);
	};
};
