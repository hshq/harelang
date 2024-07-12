// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
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
	// List of usernames that are members of this group, separated by commas
	userlist: str,
};

export type groupreader = struct {
	scan: bufio::scanner,
};

// Creates a parser for an /etc/groups-formatted file. Use [[nextgr]] to
// enumerate the groups, and [[groups_finish]] to free resources associated with
// the reader.
export fn groups_read(in: io::handle) groupreader = {
	return groupreader {
		scan = bufio::newscanner(in),
	};
};

// Frees resources associated with a [[groupreader]].
export fn groups_finish(rd: *groupreader) void = {
	bufio::finish(&rd.scan);
};

// Reads a Unix-like group entry from a [[groupreader]]. The return value is
// borrowed from the scanner.
export fn nextgr(rd: *groupreader) (grent | io::EOF | io::error | invalid) = {
	const line = match (bufio::scan_line(&rd.scan)) {
	case let ln: const str =>
		yield ln;
	case let err: io::error =>
		return err;
	case utf8::invalid =>
		return invalid;
	case io::EOF =>
		return io::EOF;
	};
	const tok = strings::tokenize(line, ":");

	let i = 0z;
	let fields: [4]str = [""...];
	for (const f => strings::next_token(&tok)) {
		defer i += 1;
		if (i >= len(fields)) {
			return invalid;
		};
		fields[i] = f;
	};

	let gid = match (strconv::stou64(fields[2])) {
	case let u: u64 =>
		yield u: unix::gid;
	case =>
		return invalid;
	};

	return grent {
		name      = fields[0],
		password  = fields[1],
		gid       = gid,
		userlist  = fields[3],
	};
};

// Frees resources associated with a [[grent]].
export fn grent_finish(ent: *grent) void = {
	free(ent.name);
	free(ent.password);
	free(ent.userlist);
};

// Frees resources associated with a slice of [[grent]]s.
export fn grents_free(ents: []grent) void = {
	for (let ent &.. ents) {
		grent_finish(ent);
	};
	free(ents);
};

fn grent_dup(ent: *grent) void = {
	ent.name = strings::dup(ent.name);
	ent.password = strings::dup(ent.password);
	ent.userlist = strings::dup(ent.userlist);
};

// Looks up a group by name in a Unix-like group file. It expects a such file at
// /etc/group. Aborts if that file doesn't exist or is not properly formatted.
//
// The user must pass the return value to [[grent_finish]] to free resources
// associated with the group.
//
// See [[nextgr]] for low-level parsing API.
export fn getgroup(name: str) (grent | void) = {
	const file = match (os::open("/etc/group")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Unable to open /etc/group");
	};
	defer io::close(file)!;

	const rd = groups_read(file);
	defer groups_finish(&rd);
	for (const ent => nextgr(&rd)!) {
		if (ent.name == name) {
			grent_dup(&ent);
			return ent;
		};
	};
};

// Looks up a group by ID in a Unix-like group file. It expects a such file at
// /etc/group. Aborts if that file doesn't exist or is not properly formatted.
//
// The user must pass the return value to [[grent_finish]] to free resources
// associated with the group.
//
// See [[nextgr]] for low-level parsing API.
export fn getgid(gid: unix::gid) (grent | void) = {
	const file = match (os::open("/etc/group")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Unable to open /etc/group");
	};
	defer io::close(file)!;

	const rd = groups_read(file);
	defer groups_finish(&rd);
	for (const ent => nextgr(&rd)!) {
		if (ent.gid == gid) {
			grent_dup(&ent);
			return ent;
		};
	};
};

// Looks up groups by user name in a Unix-like group file. It expects a such
// file at /etc/group. Aborts if that file doesn't exist or is not properly
// formatted. The caller must pass the return value to [[grents_finish]].
//
// See [[nextgr]] for low-level parsing API.
export fn getgroups(name: str) []grent = {
	const file = match (os::open("/etc/group")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Unable to open /etc/group");
	};
	defer io::close(file)!;

	const rd = groups_read(file);
	defer groups_finish(&rd);

	let groups: []grent = [];
	for (const ent => nextgr(&rd)!) {
		const tok = strings::tokenize(ent.userlist, ",");
		for (const tok => strings::next_token(&tok)) {
			if (tok == name) {
				grent_dup(&ent);
				append(groups, ent);
			};
		};
	};

	return groups;
};

@test fn nextgr() void = {
	const buf = memio::fixed(strings::toutf8(
		"root:x:0:root\n"
		"mail:x:12:\n"
		"video:x:986:alex,wmuser"));
	const rd = groups_read(&buf);
	defer groups_finish(&rd);

	const expect = [
		grent {
			name = "root",
			password = "x",
			gid = 0,
			userlist = "root",
		},
		grent {
			name = "mail",
			password = "x",
			gid = 12,
			userlist = "",
		},
		grent {
			name = "video",
			password = "x",
			gid = 986,
			userlist = "alex,wmuser",
		},
	];

	let i = 0z;
	for (const ent => nextgr(&rd)!) {
		defer i += 1;
		assert(ent.name == expect[i].name);
		assert(ent.password == expect[i].password);
		assert(ent.gid == expect[i].gid);
		assert(ent.userlist == expect[i].userlist);
	};
};
