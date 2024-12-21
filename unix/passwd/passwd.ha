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

// A Unix-like password database entry.
export type pwent = struct {
	// Login name
	username: str,
	// Optional encrypted password
	password: str,
	// Numerical user ID
	uid: unix::uid,
	// Numerical group ID
	gid: unix::gid,
	// User name or comment field
	comment: str,
	// User home directory
	homedir: str,
	// Optional user command interpreter
	shell: str,
};

export type userreader = struct {
	scan: bufio::scanner,
};

// Creates a parser for an /etc/passwd-formatted file. Use [[nextpw]] to
// enumerate the users, and [[users_finish]] to free resources associated with
// the reader.
export fn users_read(in: io::handle) userreader = {
	return groupreader {
		scan = bufio::newscanner(in),
	};
};

// Frees resources associated with a [[groupreader]].
export fn users_finish(rd: *userreader) void = {
	bufio::finish(&rd.scan);
};

// Reads a Unix-like password entry from an [[io::handle]]. The return value is
// borrowed from the reader.
export fn nextpw(rd: *userreader) (pwent | io::EOF | io::error | invalid) = {
	const line = match (bufio::scan_line(&rd.scan)) {
	case io::EOF =>
		return io::EOF;
	case let ln: const str =>
		yield ln;
	case utf8::invalid =>
		return invalid;
	case let err: io::error =>
		return err;
	};
	const tok = strings::tokenize(line, ":");

	let i = 0z;
	let fields: [7]str = [""...];
	for (const f => strings::next_token(&tok)) {
		defer i += 1;
		if (i >= len(fields)) {
			return invalid;
		};
		fields[i] = f;
	};

	const uid = match (strconv::stou64(fields[2])) {
	case let u: u64 =>
		yield u: unix::uid;
	case =>
		return invalid;
	};

	const gid = match (strconv::stou64(fields[3])) {
	case let u: u64 =>
		yield u: unix::gid;
	case =>
		return invalid;
	};

	return pwent {
		username = fields[0],
		password = fields[1],
		uid      = uid,
		gid      = gid,
		comment  = fields[4],
		homedir  = fields[5],
		shell    = fields[6],
	};
};

// Frees resources associated with a [[pwent]].
export fn pwent_finish(ent: *pwent) void = {
	free(ent.username);
	free(ent.password);
	free(ent.comment);
	free(ent.homedir);
	free(ent.shell);
};

fn pwent_dup(ent: *pwent) void = {
	ent.username = strings::dup(ent.username);
	ent.password = strings::dup(ent.password);
	ent.comment = strings::dup(ent.comment);
	ent.homedir = strings::dup(ent.homedir);
	ent.shell = strings::dup(ent.shell);
};

// Looks up a user by name in a Unix-like password file. It expects a password
// database file at /etc/passwd. Aborts if that file doesn't exist or is not
// properly formatted. The return value must be freed with [[pwent_finish]].
//
// See [[nextpw]] for low-level parsing API.
export fn getuser(username: str) (pwent | void) = {
	const file = match (os::open("/etc/passwd")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Can't open /etc/passwd");
	};
	defer io::close(file)!;

	const rd = users_read(file);
	defer users_finish(&rd);

	for (const ent => nextpw(&rd)!) {
		if (ent.username == username) {
			pwent_dup(&ent);
			return ent;
		};
	};
};

// Looks up a user by ID in a Unix-like password file. It expects a password
// database file at /etc/passwd. Aborts if that file doesn't exist or is not
// properly formatted. The return value must be freed with [[pwent_finish]].
//
// See [[nextpw]] for low-level parsing API.
export fn getuid(uid: unix::uid) (pwent | void) = {
	const file = match (os::open("/etc/passwd")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Can't open /etc/passwd");
	};
	defer io::close(file)!;

	const rd = users_read(file);
	defer users_finish(&rd);

	for (const ent => nextpw(&rd)!) {
		if (ent.uid == uid) {
			pwent_dup(&ent);
			return ent;
		};
	};
};

@test fn nextpw() void = {
	const buf = memio::fixed(strings::toutf8(
		"sircmpwn:x:1000:1000:sircmpwn's comment:/home/sircmpwn:/bin/rc\n"
		"alex:x:1001:1001::/home/alex:/bin/zsh\n"));

	const rd = users_read(&buf);
	defer users_finish(&rd);

	const expect = [
		pwent {
			username = "sircmpwn",
			password = "x",
			uid = 1000,
			gid = 1000,
			comment = "sircmpwn's comment",
			homedir = "/home/sircmpwn",
			shell = "/bin/rc",
		},
		pwent {
			username = "alex",
			password = "x",
			uid = 1001,
			gid = 1001,
			comment = "",
			homedir = "/home/alex",
			shell = "/bin/zsh",
		},
	];

	let i = 0z;
	for (const ent => nextpw(&rd)!) {
		defer i += 1;
		assert(ent.username == expect[i].username);
		assert(ent.password == expect[i].password);
		assert(ent.uid == expect[i].uid);
		assert(ent.gid == expect[i].gid);
		assert(ent.comment == expect[i].comment);
		assert(ent.homedir == expect[i].homedir);
		assert(ent.shell == expect[i].shell);
	};

	assert(i == len(expect));
};
