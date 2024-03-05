// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use memio;
use os;
use strconv;
use strings;
use unix;

// A Unix-like group file entry.
export type grent = struct {
	// Name of the group
	name: str,
	// Optional encrypted password
	password: str,
	// Numerical group ID
	gid: unix::gid,
	// List of usernames that are members of this group
	userlist: []str,
};

// Reads a Unix-like group entry from an [[io::handle]]. The caller must free
// the return value using [[grent_finish]].
export fn nextgr(in: io::handle) (grent | io::EOF | io::error | invalid) = {
	let line = match (bufio::read_line(in)?) {
	case let ln: []u8 =>
		yield ln;
	case io::EOF =>
		return io::EOF;
	};
	let line = match (strings::fromutf8(line)) {
	case let s: str =>
		yield s;
	case =>
		return invalid;
	};

	let fields = strings::split(line, ":");
	defer free(fields);

	if (len(fields) != 4) {
		return invalid;
	};

	let gid = match (strconv::stou64(fields[2])) {
	case let u: u64 =>
		yield u: unix::gid;
	case =>
		return invalid;
	};

	return grent {
		// Borrows the return value of bufio::read_line
		name      = fields[0],
		password  = fields[1],
		gid       = gid,
		userlist  = strings::split(fields[3], ","),
	};
};

// Frees resources associated with [[grent]].
export fn grent_finish(ent: *grent) void = {
	free(ent.name);
	free(ent.userlist);
};

// Looks up a group by name in a Unix-like group file. It expects a such file at
// /etc/group. Aborts if that file doesn't exist or is not properly formatted.
//
// See [[nextgr]] for low-level parsing API.
export fn getgroup(name: str) (grent | void) = {
	let file = match (os::open("/etc/group")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Unable to open /etc/group");
	};
	defer io::close(file)!;

	let rbuf: [os::BUFSZ]u8 = [0...];
	let strm = bufio::init(file, rbuf, []);
	for (true) {
		let ent = match (nextgr(&strm)) {
		case let e: grent =>
			yield e;
		case io::EOF =>
			break;
		case =>
			abort("Invalid entry in /etc/group");
		};

		if (ent.name == name) {
			return ent;
		} else {
			grent_finish(&ent);
		};
	};
};

// Looks up a group by ID in a Unix-like group file. It expects a such file at
// /etc/group. Aborts if that file doesn't exist or is not properly formatted.
//
// See [[nextgr]] for low-level parsing API.
export fn getgid(gid: unix::gid) (grent | void) = {
	let file = match (os::open("/etc/group")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Unable to open /etc/group");
	};
	defer io::close(file)!;

	let rbuf: [os::BUFSZ]u8 = [0...];
	let strm = bufio::init(file, rbuf, []);
	for (true) {
		let ent = match (nextgr(&strm)) {
		case let e: grent =>
			yield e;
		case io::EOF =>
			break;
		case =>
			abort("Invalid entry in /etc/group");
		};

		if (ent.gid == gid) {
			return ent;
		} else {
			grent_finish(&ent);
		};
	};
};

@test fn nextgr() void = {
	let buf = memio::fixed(strings::toutf8(
		"root:x:0:root\n"
		"mail:x:12:\n"
		"video:x:986:alex,wmuser"));

	let ent = nextgr(&buf) as grent;
	defer grent_finish(&ent);

	assert(ent.name == "root");
	assert(ent.password == "x");
	assert(ent.gid == 0);
	assert(len(ent.userlist) == 1);
	assert(ent.userlist[0] == "root");

	let ent = nextgr(&buf) as grent;
	defer grent_finish(&ent);

	assert(ent.name == "mail");
	assert(ent.password == "x");
	assert(ent.gid == 12);
	assert(len(ent.userlist) == 0);

	let ent = nextgr(&buf) as grent;
	defer grent_finish(&ent);

	assert(ent.name == "video");
	assert(ent.password == "x");
	assert(ent.gid == 986);
	assert(len(ent.userlist) == 2);
	assert(ent.userlist[0] == "alex");
	assert(ent.userlist[1] == "wmuser");

	// No more entries
	assert(nextgr(&buf) is io::EOF);
};
