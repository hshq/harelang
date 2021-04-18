use bufio;
use io;
use os;
use strconv;
use strings;

// A Unix-like group file entry.
export type grent = struct {
	// Name of the group
	name: str,
	// Optional encrypted password
	password: str,
	// Numerical group ID
	gid: uint,
	// List of usernames that are members of this group, comma separated
	userlist: str,
};

// Reads a Unix-like group entry from a stream. The caller must free the result
// using [grent_finish].
export fn nextgr(stream: *io::stream) (grent | io::EOF | io::error | invalid) = {
	let line = match (bufio::scanline(stream)?) {
		ln: []u8 => ln,
		io::EOF => return io::EOF,
	};
	let line = match (strings::try_fromutf8(line)) {
		s: str => s,
		* => return invalid,
	};

	let fields = strings::split(line, ":");
	defer free(fields);

	if (len(fields) != 4) {
		return invalid;
	};

	let gid = match (strconv::stou(fields[2])) {
		u: uint => u,
		* => return invalid,
	};

	return grent {
		// Borrows the return value of bufio::scanline
		name      = fields[0],
		password  = fields[1],
		gid       = gid,
		userlist  = fields[3],
	};
};

// Frees resources associated with [grent].
export fn grent_finish(ent: grent) void = {
	free(ent.name);
};

// Looks up a group by name in a Unix-like group file. It expects a such file at
// /etc/group. Aborts if that file doesn't exist or is not properly formatted.
//
// See [nextgr] for low-level parsing API.
export fn getgroup(name: str) (grent | void) = {
	let file = match (os::open("/etc/group")) {
		s: *io::stream => s,
		* => abort("Unable to open /etc/group"),
	};
	defer io::close(file);

	for (true) {
		let ent = match (nextgr(file)) {
			e: grent => e,
			io::EOF => break,
			* => abort("Invalid entry in /etc/group"),
		};

		if (ent.name == name) {
			return ent;
		} else {
			grent_finish(ent);
		};
	};

	return;
};

@test fn nextgr() void = {
	let buf = bufio::fixed(strings::toutf8(
		"root:x:0:root\n"
		"mail:x:12:\n"
		"video:x:986:alex,wmuser"), io::mode::READ);
	defer free(buf);

	let ent = nextgr(buf) as grent;
	defer grent_finish(ent);

	assert(ent.name == "root");
	assert(ent.password == "x");
	assert(ent.gid == 0);
	assert(ent.userlist == "root");

	let ent = nextgr(buf) as grent;
	defer grent_finish(ent);

	assert(ent.name == "mail");
	assert(ent.password == "x");
	assert(ent.gid == 12);
	assert(ent.userlist == "");

	let ent = nextgr(buf) as grent;
	defer grent_finish(ent);

	assert(ent.name == "video");
	assert(ent.password == "x");
	assert(ent.gid == 986);
	assert(ent.userlist == "alex,wmuser");

	// No more entries
	assert(nextgr(buf) is io::EOF);
};
