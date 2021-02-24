use io;

// Returns a human-friendly representation of an error.
export fn errstr(err: error) const str = match (err) {
	noentry => "File or directory not found",
	noaccess => "Permission denied",
	err: io::error => io::errstr(err),
};

// Converts a mode into a Unix-like mode string (e.g. "-rw-r--r--")
export fn modestr(mode: mode) const str = {
	// TODO: blocked on bufio::fixed
	abort();
};

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

// Reads all entries from a directory.
export fn readdir(fs: *fs, path: path) ([]filestat | error) = {
	let i = iter(fs, path)?;
	let ents: []filestat = [];
	for (true) {
		match (next(i)) {
			f: filestat => append(ents, stat_dup(f)),
			void => break,
		};
	};
	return ents;
};
