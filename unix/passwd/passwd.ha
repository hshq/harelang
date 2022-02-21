// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use io;
use os;
use strconv;
use strings;

// A Unix-like password database entry.
export type pwent = struct {
	// Login name
	username: str,
	// Optional encrypted password
	password: str,
	// Numerical user ID
	uid: uint,
	// Numerical group ID
	gid: uint,
	// User name or comment field
	comment: str,
	// User home directory
	homedir: str,
	// Optional user command interpreter
	shell: str,
};

// Reads a Unix-like password entry from an [[io::handle]]. The caller must free
// the result using [[pwent_finish]].
export fn nextpw(file: io::handle) (pwent | io::EOF | io::error | invalid) = {
	let line = match (bufio::scanline(file)?) {
	case io::EOF =>
		return io::EOF;
	case let ln: []u8 =>
		yield ln;
	};
	let line = match (strings::try_fromutf8(line)) {
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

	let uid = match (strconv::stou(fields[2])) {
	case let u: uint =>
		yield u;
	case =>
		return invalid;
	};

	let gid = match (strconv::stou(fields[3])) {
	case let u: uint =>
		yield u;
	case =>
		return invalid;
	};

	return pwent {
		// Borrows the return value of bufio::scanline
		username = fields[0],
		password = fields[1],
		uid      = uid,
		gid      = gid,
		comment  = fields[4],
		homedir  = fields[5],
		shell    = fields[6],
	};
};

// Frees resources associated with [[pwent]].
export fn pwent_finish(ent: pwent) void = {
	// pwent fields are sliced from one allocated string returned by
	// bufio::scanline. Freeing the first field frees the entire string in
	// one go.
	free(ent.username);
};

// Looks up a user by name in a Unix-like password file. It expects a password
// database file at /etc/passwd. Aborts if that file doesn't exist or is not
// properly formatted.
//
// See [[nextpw]] for low-level parsing API.
export fn getuser(username: str) (pwent | void) = {
	let file = match (os::open("/etc/passwd")) {
	case let f: io::file =>
		yield f;
	case =>
		abort("Can't open /etc/passwd");
	};
	defer io::close(file);

	for (true) {
		let ent = match (nextpw(file)) {
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
			pwent_finish(ent);
		};
	};

	return;
};

@test fn nextpw() void = {
	let buf = bufio::fixed(strings::toutf8(
		"sircmpwn:x:1000:1000:sircmpwn's comment:/home/sircmpwn:/bin/mrsh\n"
		"alex:x:1001:1001::/home/alex:/bin/zsh"), io::mode::READ);

	let ent = nextpw(&buf) as pwent;
	defer pwent_finish(ent);

	assert(ent.username == "sircmpwn");
	assert(ent.password == "x");
	assert(ent.uid == 1000);
	assert(ent.gid == 1000);
	assert(ent.comment == "sircmpwn's comment");
	assert(ent.homedir == "/home/sircmpwn");
	assert(ent.shell == "/bin/mrsh");

	let ent = nextpw(&buf) as pwent;
	defer pwent_finish(ent);

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
