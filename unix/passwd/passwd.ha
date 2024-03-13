// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
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

// Reads a Unix-like password entry from an [[io::handle]]. The caller must free
// the return value using [[pwent_finish]].
export fn nextpw(in: io::handle) (pwent | io::EOF | io::error | invalid) = {
	let line = match (bufio::read_line(in)?) {
	case io::EOF =>
		return io::EOF;
	case let ln: []u8 =>
		yield ln;
	};
	let line = match (strings::fromutf8(line)) {
	case let s: str =>
		yield s;
	case =>
		return invalid;
	};

	let fields = strings::split(line, ":");
	defer free(fields);

	if (len(fields) != 7) {
		return invalid;
	};

	let uid = match (strconv::stou64(fields[2])) {
	case let u: u64 =>
		yield u: unix::uid;
	case =>
		return invalid;
	};

	let gid = match (strconv::stou64(fields[3])) {
	case let u: u64 =>
		yield u: unix::gid;
	case =>
		return invalid;
	};

	return pwent {
		// Borrows the return value of bufio::read_line
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
	// pwent fields are sliced from one allocated string returned by
	// bufio::read_line. Freeing the first field frees the entire string in
	// one go.
	free(ent.username);
};

// Looks up a user by name in a Unix-like password file. It expects a password
// database file at /etc/passwd. Aborts if that file doesn't exist or is not
// properly formatted. The return value must be freed with [[pwent_finish]].
//
// See [[nextpw]] for low-level parsing API.
export fn getuser(username: str) (pwent | void) = {
	let file = match (os::open("/etc/passwd")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Can't open /etc/passwd");
	};
	defer io::close(file)!;

	let rbuf: [os::BUFSZ]u8 = [0...];
	let strm = bufio::init(file, rbuf, []);
	for (true) {
		let ent = match (nextpw(&strm)) {
		case let e: pwent =>
			yield e;
		case io::EOF =>
			break;
		case =>
			abort("Invalid entry in /etc/passwd");
		};

		if (ent.username == username) {
			return ent;
		} else {
			pwent_finish(&ent);
		};
	};
};

// Looks up a user by ID in a Unix-like password file. It expects a password
// database file at /etc/passwd. Aborts if that file doesn't exist or is not
// properly formatted. The return value must be freed with [[pwent_finish]].
//
// See [[nextpw]] for low-level parsing API.
export fn getuid(uid: unix::uid) (pwent | void) = {
	let file = match (os::open("/etc/passwd")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Can't open /etc/passwd");
	};
	defer io::close(file)!;

	let rbuf: [os::BUFSZ]u8 = [0...];
	let strm = bufio::init(file, rbuf, []);
	for (true) {
		let ent = match (nextpw(&strm)) {
		case let e: pwent =>
			yield e;
		case io::EOF =>
			break;
		case =>
			abort("Invalid entry in /etc/passwd");
		};

		if (ent.uid == uid) {
			return ent;
		} else {
			pwent_finish(&ent);
		};
	};
};

@test fn nextpw() void = {
	let buf = memio::fixed(strings::toutf8(
		"sircmpwn:x:1000:1000:sircmpwn's comment:/home/sircmpwn:/bin/mrsh\n"
		"alex:x:1001:1001::/home/alex:/bin/zsh"));

	let ent = nextpw(&buf) as pwent;
	defer pwent_finish(&ent);

	assert(ent.username == "sircmpwn");
	assert(ent.password == "x");
	assert(ent.uid == 1000);
	assert(ent.gid == 1000);
	assert(ent.comment == "sircmpwn's comment");
	assert(ent.homedir == "/home/sircmpwn");
	assert(ent.shell == "/bin/mrsh");

	let ent = nextpw(&buf) as pwent;
	defer pwent_finish(&ent);

	assert(ent.username == "alex");
	assert(ent.password == "x");
	assert(ent.uid == 1001);
	assert(ent.gid == 1001);
	assert(ent.comment == "");
	assert(ent.homedir == "/home/alex");
	assert(ent.shell == "/bin/zsh");

	// No more entries
	assert(nextpw(&buf) is io::EOF);
};
