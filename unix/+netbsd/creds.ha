// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
// Unix credentials types & functions; ref credentials(7)

use errors;
use rt;

// Process ID.
export type pid = rt::pid_t;

// User ID.
export type uid = rt::uid_t;

// Group ID.
export type gid = rt::gid_t;

// Returns the current process user ID.
export fn getuid() uid = rt::getuid() as rt::uid_t: uid;

// Returns the current process effective user ID.
export fn geteuid() uid = rt::geteuid() as rt::uid_t: uid;

// Returns the current process group ID.
export fn getgid() gid = rt::getgid() as rt::gid_t: gid;

// Returns the current process effective group ID.
export fn getegid() gid = rt::getegid() as rt::gid_t: gid;

// Sets the caller's user ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setuid(uid: uid) void = rt::setuid(&uid)!;

// Sets the caller's effective user ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from seteuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn seteuid(euid: uid) void = rt::seteuid(&euid)!;

// Sets the caller's group ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgid(gid: gid) void = rt::setgid(&gid)!;

// Sets the caller's effective group ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setegid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setegid(egid: gid) void = rt::setegid(&egid)!;

// Returns a list of supplementary group IDs for the current process. The
// returned slice is statically allocated.
export fn getgroups() []gid = {
	static let gids: [rt::NGROUPS_MAX]rt::gid_t = [0...];
	const n = rt::getgroups(gids)!;
	return gids[..n]: []gid;
};

// Sets the list of supplementary group IDs which apply to the current process.
// This generally requires elevated permissions.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setgroups is a grave security issue in your program,
// and therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgroups(gids: []gid) void = rt::setgroups(gids: []rt::gid_t)!;

// Returns the current process ID.
export fn getpid() pid = rt::getpid();

// Returns the parent process ID.
export fn getppid() pid = rt::getppid();

// Returns the current process group ID.
export fn getpgrp() pid = rt::getpgrp();

// Returns the current process's session ID.
export fn getsid() pid = rt::getsid(0)!;

// Returns the session ID associated with the given process.
export fn getpsid(pid: pid) (pid | errors::noentry | errors::noaccess) = {
	match (rt::getsid(pid)) {
	case let pid: rt::pid_t =>
		return pid;
	case let err: rt::errno =>
		assert(err == rt::ESRCH);
		return errors::noentry;
	};
};
